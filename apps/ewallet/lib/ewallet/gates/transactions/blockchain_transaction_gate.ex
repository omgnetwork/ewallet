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

  require Logger

  alias EWallet.{
    BlockchainTransactionPolicy,
    TokenFetcher,
    Helper,
    BlockchainLocalTransactionGate,
    TransactionRegistry,
    TransactionTracker,
    BlockchainHelper
  }

  alias EWalletDB.{BlockchainWallet, Transaction, TransactionState}
  alias ActivityLogger.System

  @external_transaction Transaction.external()
  @deposit_transaction Transaction.deposit()

  @rootchain_identifier BlockchainHelper.rootchain_identifier()
  @childchain_identifier BlockchainHelper.childchain_identifier()

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
    primary_hot_wallet = BlockchainWallet.get_primary_hot_wallet(@rootchain_identifier)

    with {:ok, _} <- BlockchainTransactionPolicy.authorize(:create, actor, attrs),
         true <-
           primary_hot_wallet.address == from ||
             :from_blockchain_address_is_not_primary_hot_wallet,
         %{} = attrs <- set_payload(attrs),
         %{} = attrs <- set_blockchain_addresses(attrs),
         %{} = attrs <- set_token(attrs),
         %{} = attrs <- check_amount(attrs),
         true <- enough_funds?(attrs) || {:error, :insufficient_funds_in_hot_wallet},
         %{} = attrs <- set_blockchain(attrs),
         {:ok, transaction} <- get_or_insert(attrs),
         {:ok, transaction} <- submit_if_needed(transaction, :from_ewallet_to_blockchain) do
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

  # Sends funds out of an internal wallet to a blockchain address
  #
  # Steps:
  # 1. Insert a local transaction with status: "pending"
  # 2. Submit a transaction to the blockchain
  # 3. Start a transaction tracker to confirm the local transaction after enough confirmations
  def create(actor, attrs, {false, true}) do
    primary_hot_wallet = BlockchainWallet.get_primary_hot_wallet(@rootchain_identifier)

    with {:ok, _} <- BlockchainTransactionPolicy.authorize(:create, actor, attrs),
         %{} = attrs <- set_payload(attrs),
         %{} = attrs <- set_internal_and_blockchain_addresses(attrs, primary_hot_wallet),
         %{} = attrs <- set_token(attrs),
         %{} = attrs <- check_amount(attrs),
         true <- enough_funds?(attrs) || {:error, :insufficient_funds_in_hot_wallet},
         %{} = attrs <- set_blockchain(attrs),
         {:ok, transaction} <- get_or_insert(attrs),
         {:ok, transaction} <-
           BlockchainLocalTransactionGate.process_with_transaction(transaction),
         {:ok, transaction} <- submit_if_needed(transaction, :from_ledger_to_blockchain) do
      {:ok, transaction}
    else
      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  # Handle external -> hot wallet (not registered in local ledger)
  # Handle external -> internal wallet (registered in local ledger)
  def create_from_tracker(attrs) do
    case Transaction.insert(attrs) do
      {:ok, transaction} ->
        # TODO: handle error?
        {:ok, transaction} = confirm_or_start_listener(transaction)

        case transaction do
          %{status: "blockchain_confirmed"} ->
            handle_local_insert(transaction)

          transaction ->
            {:ok, transaction}
        end

      error ->
        error
    end
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
    Enum.map(addresses, fn address ->
      case BlockchainHelper.validate_blockchain_address(address) do
        :ok -> true
        _ -> false
      end
    end)
  end

  defp confirm_or_start_listener(
         %{confirmations_count: confirmations_count, to: to} = transaction
       ) do
    threshold = Application.get_env(:ewallet, :blockchain_confirmations_threshold)
    flow = if(is_nil(to), do: :from_blockchain_to_ewallet, else: :from_blockchain_to_ledger)

    if is_nil(threshold) do
      Logger.warn("Blockchain Confirmations Threshold not set in configuration: using 10.")
    end

    # TODO: merge with the logic in TransactionTraker
    case is_integer(confirmations_count) && confirmations_count > (threshold || 10) do
      true ->
        # TODO: Change originator?
        TransactionState.transition_to(
          flow,
          TransactionState.blockchain_confirmed(),
          transaction,
          %{
            confirmations_count: confirmations_count,
            originator: %System{}
          }
        )

      false ->
        :ok =
          TransactionRegistry.start_tracker(TransactionTracker, %{
            transaction: transaction,
            transaction_type: flow
          })

        {:ok, transaction}
    end
  end

  # The destination is nil when the transaction is intended to arrive and stay
  # in the hot wallet, not part of any local ledger wallet, not even the master wallet.
  # Therefore, we do not proceed to BlockchainLocalTransactionGate in this case and simply
  # move the transaction to confirmed state.
  def handle_local_insert(%{to: nil} = transaction) do
    TransactionState.transition_to(
      :from_blockchain_to_ewallet,
      TransactionState.confirmed(),
      transaction,
      %{originator: %System{}}
    )
  end

  def handle_local_insert(transaction) do
    BlockchainLocalTransactionGate.process_with_transaction(transaction)
  end

  defp set_blockchain_addresses(attrs) do
    attrs
    |> Map.put("to_blockchain_address", attrs["to_address"])
    |> Map.put("from_blockchain_address", attrs["from_address"])
    |> Map.delete("to_address")
    |> Map.delete("from_address")
  end

  defp set_internal_and_blockchain_addresses(attrs, hot_wallet) do
    attrs
    |> Map.put("from", attrs["from_address"])
    |> Map.put("to_blockchain_address", attrs["to_address"])
    |> Map.put("from_blockchain_address", hot_wallet.address)
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

  defp enough_funds?(%{"blockchain_identifier" => @childchain_identifier} = attrs) do
    attrs
    |> get_childchain_balance()
    |> process_balance_response(attrs)
  end

  defp enough_funds?(%{"blockchain_identifier" => @rootchain_identifier} = attrs) do
    attrs
    |> get_rootchain_balance()
    |> process_balance_response(attrs)
  end

  defp get_rootchain_balance(%{
         "from_blockchain_address" => address,
         "from_token" => token
       }) do
    BlockchainHelper.call(:get_balances, %{
      address: address,
      contract_addresses: [token.blockchain_address]
    })
  end

  defp get_childchain_balance(%{"from_blockchain_address" => address}) do
    BlockchainHelper.call(:get_childchain_balance, %{address: address})
  end

  defp process_balance_response({:ok, balances}, %{"from_token" => token, "from_amount" => amount}) do
    (balances[token.blockchain_address] || 0) > amount
  end

  defp process_balance_response(_error, _attrs), do: false

  defp set_blockchain(attrs) do
    attrs
    |> Map.put_new("blockchain_identifier", @rootchain_identifier)
    |> Map.put_new("type", @external_transaction)
  end

  defp set_payload(attrs) do
    Map.put(attrs, "payload", Map.delete(attrs, "originator"))
  end

  defp check_amount(%{"amount" => amount} = attrs) when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, converted} -> attrs |> Map.put("amount", converted) |> check_amount()
      error -> error
    end
  end

  defp check_amount(%{"amount" => amount} = attrs) when is_integer(amount) do
    attrs
    |> Map.put("from_amount", amount)
    |> Map.put("to_amount", amount)
    |> Map.delete("amount")
  end

  defp check_amount(%{"amount" => amount}) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount` must be an integer or integer string." <>
       " Given: #{inspect(amount)}."}
  end

  defp check_amount(%{"from_amount" => from_amount} = attrs) when is_binary(from_amount) do
    case Helper.string_to_integer(from_amount) do
      {:ok, converted} -> attrs |> Map.put("from_amount", converted) |> check_amount()
      error -> error
    end
  end

  defp check_amount(%{"to_amount" => to_amount} = attrs) when is_binary(to_amount) do
    case Helper.string_to_integer(to_amount) do
      {:ok, converted} -> attrs |> Map.put("to_amount", converted) |> check_amount()
      error -> error
    end
  end

  defp check_amount(%{"from_amount" => from_amount, "to_amount" => to_amount})
       when is_integer(from_amount) and is_integer(to_amount) and from_amount != to_amount do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `from_amount` and `to_amount` must be equal." <>
       " Given: #{inspect(from_amount)} and #{inspect(to_amount)} respectively."}
  end

  defp check_amount(%{"from_amount" => from_amount, "to_amount" => to_amount} = attrs)
       when is_integer(from_amount) and is_integer(to_amount) do
    attrs
  end

  defp check_amount(%{"from_amount" => from_amount, "to_amount" => to_amount}) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `from_amount` and `to_amount` must be integers or integer strings." <>
       " Given: #{inspect(from_amount)} and #{inspect(to_amount)} respectively."}
  end

  defp check_amount(_) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount`, `from_amount` or `to_amount` is required."}
  end

  defp submit_if_needed(%{blockchain_tx_hash: nil} = transaction, type) do
    with {:ok, tx_hash} <- submit(transaction),
         {:ok, transaction} <-
           TransactionState.transition_to(
             type,
             TransactionState.blockchain_submitted(),
             transaction,
             %{blockchain_tx_hash: tx_hash, originator: %System{}}
           ),
         :ok =
           TransactionRegistry.start_tracker(TransactionTracker, %{
             transaction: transaction,
             transaction_type: type
           }) do
      {:ok, transaction}
    end

    # TODO: Handle submit failure -> Change tx status to failed -> Record error
  end

  defp submit_if_needed(transaction, _type), do: {:ok, transaction}

  defp submit(
         %{type: @external_transaction, blockchain_identifier: @childchain_identifier} =
           transaction
       ) do
    attrs = %{
      from: transaction.from_blockchain_address,
      to: transaction.to_blockchain_address,
      amount: transaction.from_amount,
      currency: transaction.from_token.blockchain_address,
      childchain_identifier: String.to_existing_atom(@childchain_identifier)
    }

    :transfer_on_childchain
    |> BlockchainHelper.call(attrs)
    |> process_childchain_transaction()
  end

  defp submit(%{type: @external_transaction} = transaction) do
    attrs = %{
      from: transaction.from_blockchain_address,
      to: transaction.to_blockchain_address,
      amount: transaction.from_amount,
      contract_address: transaction.from_token.blockchain_address
    }

    BlockchainHelper.call(:send, attrs)
  end

  defp submit(%{type: @deposit_transaction} = transaction) do
    {cc_id, _} = Application.get_env(:ewallet, :cc_node_adapter)

    attrs = %{
      childchain_identifier: cc_id,
      amount: transaction.from_amount,
      currency: transaction.from_token.blockchain_address,
      to: transaction.from_blockchain_address
    }

    BlockchainHelper.call(:deposit_to_childchain, attrs)
  end

  defp process_childchain_transaction({:ok, tx_hash, _blk_num, _tx_index}) do
    # TODO: process blk_num and tx_index ?
    {:ok, tx_hash}
  end

  defp process_childchain_transaction(error) do
    error
  end
end
