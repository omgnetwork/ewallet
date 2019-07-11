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

defmodule EWallet.BlockchainTransactionGate do
  @moduledoc """
  Handles the logic for blockchain transactions. Validates the inputs, inserts the
  initial transaction before calling a Transaction Tracker that will take care
  of updating the fields based on events coming from the blockchain side.

  This is using a different approach than the LocalTransactionGate
  for simplicity (modifying the existing inputs instead of creating new
  data structures).
  """
  alias EWallet.{
    BlockchainTransactionPolicy,
    TokenFetcher,
    BlockchainTransactionState,
    TransactionRegistry,
    TransactionTracker
  }

  alias EWalletDB.{BlockchainWallet, Transaction}
  alias ActivityLogger.System

  # TODO: Check if blockchain is enabled
  # TODO: Check if blockchain is available
  # TODO: Add tests at the controller level
  # TODO: Add tests for failures at the gate level

  @doc """
  Here, we send a transaction from the hot wallet to
  an external blockchain address. This should only be used to manage
  the funds repartition between hot and cold wallets.

  The last parameter represents the validity of the from / to addresses
  as blockchain addresses: {true, true} means they are both valid
  blockchain addresses.
  """
  def create(actor, %{"from_address" => from} = attrs, {true, true}) do
    primary_hot_wallet = BlockchainWallet.get_primary_hot_wallet()

    with {:ok, _} <- BlockchainTransactionPolicy.authorize(:create, actor, attrs),
         true <-
           primary_hot_wallet.address == from ||
             :from_blockchain_address_is_not_primary_hot_wallet,
         %{} = attrs <- set_payload(attrs),
         %{} = attrs <- set_blockchain_addresses(attrs),
         %{} = attrs <- set_token(attrs),
         %{} = attrs <- check_amount(attrs),
         true <-
           enough_funds?(from, attrs["from_token"], attrs["from_amount"]) ||
             {:error, :insufficient_funds},
         %{} = attrs <- set_blockchain(attrs),
         {:ok, transaction} <- get_or_insert(attrs),
         {:ok, tx_hash} <- submit(transaction),
         {:ok, transaction} <-
           BlockchainTransactionState.transition_to(:submitted, transaction, tx_hash, %System{}),
         :ok = TransactionRegistry.start_tracker(TransactionTracker, transaction) do
      {:ok, transaction}
    else
      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  # Error: we can't handle a transaction from hot wallet to something
  # other than a blockchain address
  def create(_actor, _attrs, {true, false}) do
    {:error, :invalid_to_address_for_blockchain_transaction}
  end

  # Here we're handling a regular transaction getting funds out of an
  # internal wallet to a blockchain address
  def create(_actor, _attrs, {false, true}) do
    # TODO: Next PR
    {:error, :not_implemented}
  end

  def get_or_insert(
        %{
          "idempotency_token" => _idempotency_token
        } = attrs
      ) do
    Transaction.get_or_insert(attrs)
  end

  def get_or_insert(_) do
    {:error, :invalid_parameter, "Invalid parameter provided. `idempotency_token` is required."}
  end

  def blockchain_addresses?(addresses) do
    adapter = Application.get_env(:ewallet, :blockchain_adapter)

    Enum.map(addresses, fn address ->
      adapter.helper.is_adapter_address?(address)
    end)
  end

  defp set_blockchain_addresses(attrs) do
    attrs
    |> Map.put("to_blockchain_address", attrs["to_address"])
    |> Map.put("from_blockchain_address", attrs["from_address"])
    |> Map.delete("to_address")
    |> Map.delete("from_address")
  end

  defp set_token(attrs) do
    # TODO: add check for blockchain token status
    with {:ok, %{from_token: from_token}, %{to_token: to_token}} <-
           TokenFetcher.fetch(attrs, %{}, %{}),
         true <-
           is_binary(from_token.blockchain_address) || {:error, :token_not_blockchain_enabled},
         true <- from_token.uuid == to_token.uuid || {:error, :blockchain_exchange_not_allowed} do
      attrs
      |> Map.put("from_token_uuid", from_token.uuid)
      |> Map.put("from_token", from_token)
      |> Map.put("to_token_uuid", from_token.uuid)
      |> Map.put("to_token", from_token)
    else
      error -> error
    end
  end

  defp enough_funds?(address, token, amount) do
    blockchain_adapter = Application.get_env(:ewallet, :blockchain_adapter)
    node_adapter = Application.get_env(:ewallet, :node_adapter)

    # TODO: handle errors
    {:ok, balances} =
      blockchain_adapter.call(
        {:get_balances,
         %{
           address: address,
           contract_addresses: [token.blockchain_address]
         }},
        node_adapter
      )

    (balances[token.blockchain_address] || 0) > amount
  end

  defp set_blockchain(attrs) do
    adapter = Application.get_env(:ewallet, :blockchain_adapter)

    attrs
    |> Map.put("blockchain_identifier", adapter.helper.identifier)
    |> Map.put("type", Transaction.external())
  end

  defp set_payload(attrs) do
    Map.put(attrs, "payload", Map.delete(attrs, "originator"))
  end

  defp check_amount(%{"from_amount" => from_amount, "to_amount" => from_amount} = attrs),
    do: attrs

  defp check_amount(%{"amount" => amount} = attrs) do
    attrs
    |> Map.put("from_amount", amount)
    |> Map.put("to_amount", amount)
  end

  defp check_amount(_), do: {:error, :amounts_missing_or_invalid}

  defp submit(transaction) do
    blockchain_adapter = Application.get_env(:ewallet, :blockchain_adapter)
    node_adapter = Application.get_env(:ewallet, :node_adapter)

    attrs = %{
      from: transaction.from_blockchain_address,
      to: transaction.to_blockchain_address,
      amount: transaction.from_amount,
      contract_address: transaction.from_token.blockchain_address
    }

    blockchain_adapter.call({:send, attrs}, node_adapter)
  end
end
