# Copyright 2017-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.TokenGate do
  @moduledoc """
  Handles tokens.
  """
  alias ExternalLedgerDB.TemporaryAdapter
  alias EWallet.{Helper, MintGate}
  alias EWalletDB.{Account, Token}
  alias ExternalLedgerDB.Token, as: LedgerToken
  alias Utils.Helpers.Unit

  @doc """
  Creates a new token.
  """
  @spec create(map()) :: {:ok, %Token{}} | {:error, Error.Changeset.t()}
  def create(%{"amount" => amount} = attrs) when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} -> attrs |> Map.put("amount", amount) |> create()
      error -> error
    end
  end

  def create(attrs) do
    {:ok, token} =
      attrs
      |> Map.put("ledger", LocalLedgerDB.identifier())
      |> Map.put("account_uuid", Account.get_master_account().uuid)
      |> Token.insert()

    case mint_after_create(token, attrs) do
      {:ok, _} -> {:ok, token}
      error -> error
    end
  end

  defp mint_after_create(token, %{"amount" => amount} = attrs) when is_number(amount) and amount > 0 do
    MintGate.mint_token(token, %{
      "amount" => amount,
      "originator" => attrs["originator"]
    })
  end

  defp mint_after_create(_, %{"amount" => amount}) do
    {:error, :invalid_parameter, "Invalid amount provided: '#{amount}'."}
  end

  defp mint_after_create(_, _) do
    {:ok, nil}
  end

  @doc """
  Imports a token.
  """
  @spec import(map()) :: {:ok, %Token{}} | {:error, Error.Changeset.t()}
  def import(attrs) do
    with {:ok, parsed} <- parse_import_attrs(attrs),
         {:symbol, nil} <- {:symbol, Token.get_by(symbol: parsed.symbol)},
         {:name, nil} <- {:name, Token.get_by(name: parsed.name)},
         nil <- LedgerToken.get_by(contract_address: parsed.contract_address),
         {:ok, token} <- Token.insert(parsed),
         parsed <- Map.put(parsed, :id, token.id),
         {:ok, _} <- LedgerToken.insert(parsed) do
      {:ok, token}
    else
      {:symbol, token} ->
        {:error, :token_already_exists,
         "A token with the symbol '#{token.symbol}' already exists."}

      {:name, token} ->
        {:error, :token_already_exists,
         "A token with the name '#{token.name}' already exists."}

      %LedgerToken{} = token ->
        {:error, :token_already_exists,
         "A token with the contract address '#{token.contract_address}' already exists."}

      error -> error
    end
  end

  defp parse_import_attrs(attrs) do
    with contract_address <- attrs["contract_address"],
         adapter <- attrs["adapter"],
         true <- TemporaryAdapter.valid_adapter?(adapter) || :invalid_adapter,
         {:ok, contract_data} <- TemporaryAdapter.fetch_token(contract_address, adapter),
         name <- attrs["name"] || contract_data.name,
         symbol <- attrs["symbol"] || contract_data.symbol,
         subunit_to_unit <- attrs["subunit_to_unit"] || Unit.decimals_to_subunit(contract_data.decimals),
         originator <- attrs["originator"],
         account_uuid <- attrs["account_uuid"] do
      {:ok, %{
        ledger: ExternalLedgerDB.identifier(),
        contract_address: contract_address,
        adapter: adapter,
        name: name,
        symbol: symbol,
        subunit_to_unit: subunit_to_unit,
        originator: originator,
        account_uuid: account_uuid
      }}
    else
      :invalid_adapter ->
        {:error, :invalid_parameter,
         "Invalid parameter provided. `adapter` must be one of #{
           inspect(TemporaryAdapter.adapters())
         }."}

      error ->
        error
    end
  end
end
