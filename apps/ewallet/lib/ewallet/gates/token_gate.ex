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

defmodule EWallet.TokenGate do
  @moduledoc false

  alias ActivityLogger.System
  alias EWallet.{AddressTracker, BlockchainTransactionGate, BlockchainHelper, Helper}
  alias EWalletDB.{BlockchainWallet, BlockchainTransactionState, Repo, Token}

  @confirmed Token.Blockchain.status_confirmed()
  @blockchain_transaction_confirmed BlockchainTransactionState.confirmed()
  @blockchain_transaction_failed BlockchainTransactionState.failed()

  @doc """
  Attemps to deploy an ERC-20 token contract with specified, validated attributes.
  Returns {:ok, updated_attrs} if a transaction has been successfuly submitted where `updated_attrs` is a map containing
  the initial attrs + `tx_hash`, `blockchain_address`, `contract_uuid`,`blockchain_status` and `blockchain_identifier`.
  Or {:error, code} || {:error, code, description} otherwise
  """

  def deploy_erc20(params) do
    with {:ok, valid_params} <- validate_parameter_types(params),
         {:ok, attrs} <- validate_and_normalize_attributes(valid_params) do
      decimals = attrs["subunit_to_unit"] |> :math.log10() |> trunc()
      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      case BlockchainTransactionGate.deploy_erc20_token(
             %{
               decimals: decimals,
               from: hot_wallet.address,
               initial_amount: attrs["amount"],
               locked: attrs["locked"],
               name: attrs["name"],
               symbol: attrs["symbol"]
             },
             rootchain_identifier
           ) do
        {:ok,
         %{
           contract_address: contract_address,
           blockchain_transaction: blockchain_transaction,
           contract_uuid: contract_uuid
         }} ->
          AddressTracker.register_contract_address(contract_address)
          {:ok, put_deploy_data(attrs, blockchain_transaction, contract_address, contract_uuid)}

        error ->
          error
      end
    end
  end

  @spec validate_parameter_types(map()) ::
          {:ok, map()} | {:error, :invalid_parameter, String.t()}
  defp validate_parameter_types(
         %{
           "name" => name,
           "symbol" => symbol,
           "subunit_to_unit" => subunit_to_unit,
           "amount" => amount,
           "locked" => locked
         } = parameters
       ) do
    with true <- is_binary(name),
         true <- is_binary(symbol),
         true <- is_integer(subunit_to_unit),
         true <- is_integer(amount) or is_binary(amount),
         true <- is_boolean(locked) do
      {:ok, parameters}
    else
      _ ->
        {:error, :invalid_parameter,
         "`name`, `symbol`, `subunit_to_unit`, `locked` and `amount` are required when deploying an ERC20 token."}
    end
  end

  defp validate_parameter_types(_) do
    {:error, :invalid_parameter,
     "`name`, `symbol`, `subunit_to_unit`, `locked` and `amount` are required when deploying an ERC20 token."}
  end

  @spec validate_and_normalize_attributes(map()) ::
          {:ok, map()} | {:error, :invalid_parameter, String.t()}
  defp validate_and_normalize_attributes(
         %{
           "subunit_to_unit" => subunit_to_unit,
           "amount" => amount
         } = parameters
       ) do
    with true <-
           subunit_to_unit > 0 ||
             {:error, :invalid_parameter, "`subunit_to_unit` must be greater than 0."},
         true <-
           normalize_amount(amount) > 0 ||
             {:error, :invalid_parameter, "`amount` must be greater than or equal to 0."} do
      {:ok, Map.put(parameters, "amount", normalize_amount(amount))}
    end
  end

  @spec normalize_amount(String.t() | integer()) :: integer()
  defp normalize_amount(amount) do
    case is_binary(amount) do
      true ->
        {:ok, integer_amount} = Helper.string_to_integer(amount)
        integer_amount

      false ->
        amount
    end
  end

  defp put_deploy_data(attrs, blockchain_transaction, contract_address, contract_uuid) do
    attrs
    |> Map.put("blockchain_transaction_uuid", blockchain_transaction.uuid)
    |> Map.put("blockchain_address", contract_address)
    |> Map.put("contract_uuid", contract_uuid)
    |> Map.put("blockchain_status", Token.Blockchain.status_pending())
    |> Map.put("blockchain_identifier", BlockchainHelper.rootchain_identifier())
  end

  @doc """
  Validate that the `decimals` and `symbol` of the token are the same as
  the ones defined in the erc20 contract. If the contract does not implement
  these fields, we rely on the token's field values.
  Returns {:ok, status} where `status` is the blockchain status of the token.
  The status is "confirmed" if the hot wallet balance is positive, or "pending" otherwise.
  """
  def validate_erc20_readiness(contract_address, %{
        "symbol" => symbol,
        "subunit_to_unit" => subunit_to_unit
      }) do
    validate_erc20_readiness(contract_address, %{symbol: symbol, subunit_to_unit: subunit_to_unit})
  end

  def validate_erc20_readiness(contract_address, %{
        symbol: symbol,
        subunit_to_unit: subunit_to_unit
      }) do
    with {:ok, erc20_attrs} <- get_erc20_capabilities(contract_address),
         :ok <- validate_decimals(erc20_attrs, subunit_to_unit),
         :ok <- validate_symbol(erc20_attrs, symbol) do
      {:ok, get_blockchain_status(erc20_attrs)}
    else
      :error -> {:error, :token_not_matching_contract_info}
      error -> error
    end
  end

  # The contract returned a value for the `decimals()` function.
  # We can check if the internal token decimal mathches this value.
  defp validate_decimals(%{decimals: value}, subunit_to_unit) do
    case value == :math.log10(subunit_to_unit) do
      true -> :ok
      false -> :error
    end
  end

  # The contract doesn't implement the optional `decimals()` function
  # It's still potentially an ERC20 contract
  defp validate_decimals(_, _), do: :ok

  # The internal token symbol matches the contract symbol
  defp validate_symbol(%{symbol: value}, value), do: :ok

  # The internal token symbol doesn't matches the contract symbol
  defp validate_symbol(%{symbol: _value}, _diff_value), do: :error

  # The contract doesn't implement the optional `symbol()` function
  # It's still potentially an ERC20 contract
  defp validate_symbol(_, _), do: :ok

  @doc """
  Returns the blockchain of the token by checking if the hot wallet balance is positive
  for this token
  """
  def get_blockchain_status(%{hot_wallet_balance: balance}) when balance > 0 do
    Token.Blockchain.status_confirmed()
  end

  def get_blockchain_status(%{hot_wallet_balance: _balance}) do
    Token.Blockchain.status_pending()
  end

  @doc """
  Check the if the given contract implements the required read only ERC20 functions.
  This will check 2 required functions:
  - totalSupply()
  - balanceOf(address)
  And 3 optional functions:
  - name()
  - symbol()
  - decimals()
  Will return {:ok, info} if the 2 required function are present in the contract definition.
  Where info is a map that contains `total_supply` and optionally `name`, `symbol` and `decimals`
  if found.
  Will return {:error, :token_not_erc20} if the contract does not implement the required functions
  Will return {:error, :error_code} or {:error, :error_code, message} if an error occured.
  """
  @spec get_erc20_capabilities(String.t()) ::
          {:ok, map()} | {:error, atom()} | {:error, atom(), String.t()}
  def get_erc20_capabilities(contract_address) do
    with {:ok, mandatory_info} <- get_mandatory(contract_address),
         {:ok, optional_info} <- get_optional(contract_address) do
      {:ok, Map.merge(mandatory_info, optional_info)}
    else
      error ->
        error
    end
  end

  defp get_optional(contract_address) do
    with {:ok, name} <- get_field("name", contract_address),
         {:ok, symbol} <- get_field("symbol", contract_address),
         {:ok, decimals} <- get_field("decimals", contract_address) do
      {:ok, %{name: name, symbol: symbol, decimals: decimals}}
    else
      {:error, :field_not_found} -> {:ok, %{}}
      error -> error
    end
  end

  defp get_mandatory(contract_address) do
    with {:ok, total_supply} <- get_field("totalSupply", contract_address),
         {:ok, %{^contract_address => balance}} <- get_balances(contract_address),
         true <- !is_nil(balance) || {:error, :token_not_erc20} do
      {:ok, %{total_supply: total_supply, hot_wallet_balance: balance}}
    else
      {:error, :token_not_erc20} = error -> error
      {:error, :field_not_found} -> {:error, :token_not_erc20}
      error -> error
    end
  end

  defp get_field(field, contract_address) do
    BlockchainHelper.call(:get_field, %{
      field: field,
      contract_address: contract_address
    })
  end

  defp get_balances(contract_address) do
    identifier = BlockchainHelper.rootchain_identifier()

    BlockchainHelper.call(:get_balances, %{
      address: BlockchainWallet.get_primary_hot_wallet(identifier).address,
      contract_addresses: [contract_address]
    })
  end

  # This is called by the deployed token tracker when the creating blockchain transaction
  # reaches the `confirmed` state.
  def on_deployed_transaction_confirmed(%{blockchain_status: @confirmed} = token),
    do: {:ok, token}

  def on_deployed_transaction_confirmed(
        %{blockchain_transaction: %{status: @blockchain_transaction_confirmed}} = token
      ) do
    token
    |> Token.Blockchain.blockchain_status_changeset(%{
      blockchain_status: @confirmed,
      originator: %System{}
    })
    |> Repo.update_record_with_activity_log()
  end

  def on_deployed_transaction_confirmed(%{
        blockchain_transaction: %{status: @blockchain_transaction_failed}
      }) do
    # TODO: Handle failure, for now we leave the token in `pending` state forever
  end
end
