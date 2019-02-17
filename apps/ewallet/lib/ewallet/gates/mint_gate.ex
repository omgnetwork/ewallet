# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.MintGate do
  @moduledoc """
  Handles the mint creation logic. Since it relies on external applications to
  handle the transactions (i.e. LocalLedger), a callback needs to be passed. See
  examples on how to add value to a token.
  """
  alias Ecto.{Multi, UUID}
  alias EWallet.{GenesisGate, Helper, TokenFetcher}
  alias EWalletDB.{Account, Mint, Repo, Token}

  @spec mint_token({:ok, %Token{}} | %Token{} | {:error, Ecto.Changeset.t()} | any(), map()) ::
          {:ok, %Mint{}, %Token{}}
          | {:error, atom()}
          | {:error, atom(), String.t()}
          | {:error, Ecto.Changeset.t()}
  def mint_token({:ok, token}, attrs) do
    mint_token(token, attrs)
  end

  def mint_token(token, %{"amount" => amount} = attrs)
      when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} ->
        attrs = Map.put(attrs, "amount", amount)
        mint_token(token, attrs)

      error ->
        error
    end
  end

  def mint_token(token, %{"amount" => amount} = attrs)
      when is_number(amount) do
    %{
      "idempotency_token" => attrs["idempotency_token"] || UUID.generate(),
      "token_id" => token.id,
      "amount" => amount,
      "description" => attrs["description"],
      "originator" => attrs["originator"]
    }
    |> insert()
    |> case do
      {:ok, mint, _entry} -> {:ok, mint, token}
      {:error, code, description, mint} -> {:error, code, description, mint}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def mint_token({:error, changeset}, _attrs), do: {:error, changeset}
  def mint_token(_, _attrs), do: {:error, :invalid_parameter}

  @doc """
  Insert a new mint for a token, adding more value to it which can then be
  given to users.
  ## Examples
    res = MintGate.insert(%{
      "idempotency_token" => idempotency_token,
      "token_id" => token_id,
      "amount" => 100_000,
      "description" => "Another mint bites the dust.",
      "metadata" => %{probably: "something useful. Or not."},
      "encrypted_metadata" => %{something: "secret."},
    })
    case res do
      {:ok, mint, transaction} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # insert failed.
      {:error, changeset} ->
        # Something went wrong, check the errors in the changeset!
    end
  """
  @spec insert(map()) ::
          {:ok, %Mint{}, %EWalletDB.Transaction{}}
          | {:error, Ecto.Changeset.t()}
          | {:error, atom(), String.t()}
  def insert(
        %{
          "idempotency_token" => idempotency_token,
          "token_id" => token_id,
          "amount" => amount,
          "description" => description,
          "originator" => originator
        } = attrs
      ) do
    with {:ok, token} <- TokenFetcher.fetch(%{"token_id" => token_id}),
         %Account{} = account <- Account.get_master_account() do
      multi =
        Multi.new()
        |> Multi.run(:mint, fn _repo, _data ->
          Mint.insert(%{
            token_uuid: token.uuid,
            amount: amount,
            account_uuid: account.uuid,
            description: description,
            originator: originator
          })
        end)
        |> Multi.run(:transaction, fn _repo, %{mint: mint} ->
          GenesisGate.create(%{
            idempotency_token: idempotency_token,
            amount: amount,
            token: token,
            account: account,
            attrs: attrs,
            originator: mint
          })
        end)
        |> Multi.run(:mint_with_transaction, fn _repo, %{transaction: transaction, mint: mint} ->
          Mint.update(mint, %{
            transaction_uuid: transaction.uuid,
            originator: transaction
          })
        end)

      case Repo.transaction(multi) do
        {:ok, result} ->
          GenesisGate.process_with_transaction(result.transaction, result.mint_with_transaction)

        {:error, _failed_operation, changeset, _changes_so_far} ->
          {:error, changeset}
      end
    else
      error -> error
    end
  end
end
