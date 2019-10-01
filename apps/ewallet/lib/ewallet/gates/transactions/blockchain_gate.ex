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

defmodule EWallet.TransactionGate.Blockchain do
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
    BlockchainTransactionGate,
    TokenFetcher,
    Helper,
    TransactionGate,
    TransactionRegistry,
    TransactionTracker,
    BlockchainHelper
  }

  alias EWalletDB.{BlockchainWallet, Transaction, TransactionState}
  alias ActivityLogger.System

  @external_transaction Transaction.external()
  @deposit_transaction Transaction.deposit()

  @rootchain_identifier BlockchainHelper.rootchain_identifier()

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
    hot_wallet = BlockchainWallet.get_primary_hot_wallet(@rootchain_identifier)

    with {:ok, _} <- BlockchainTransactionPolicy.authorize(:create, actor, attrs),
         true <- hot_wallet.address == from || :from_blockchain_address_is_not_primary_hot_wallet,
         {:ok, transaction} <- insert_transaction(attrs, hot_wallet, false),
         {:ok, transaction} <- submit_if_needed(transaction, :from_ewallet_to_blockchain, attrs) do
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
    hot_wallet = BlockchainWallet.get_primary_hot_wallet(@rootchain_identifier)

    with {:ok, _} <- BlockchainTransactionPolicy.authorize(:create, actor, attrs),
         {:ok, transaction} <- insert_transaction(attrs, hot_wallet, true),
         {:ok, transaction} <-
           TransactionGate.BlockchainLocal.process_with_transaction(transaction),
         {:ok, transaction} <- submit_if_needed(transaction, :from_ledger_to_blockchain, attrs) do
      {:ok, transaction}
    else
      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  defp insert_transaction(attrs, hot_wallet, is_from_internal) do
    with %{} = attrs <- set_payload(attrs),
         %{} = attrs <- set_blockchain_addresses(attrs, hot_wallet, is_from_internal),
         %{} = attrs <- set_token(attrs),
         %{} = attrs <- check_amount(attrs),
         true <- enough_funds?(attrs) || {:error, :insufficient_funds_in_hot_wallet},
         %{} = attrs <- set_blockchain(attrs) do
      get_or_insert(attrs)
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
  # Therefore, we do not proceed to TransactionGate.BlockchainLocal in this case and simply
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
    TransactionGate.BlockchainLocal.process_with_transaction(transaction)
  end

  defp set_blockchain_addresses(attrs, hot_wallet, is_from_internal) do
    attrs =
      case is_from_internal do
        true -> Map.put(attrs, "from", attrs["from_address"])
        false -> attrs
      end

    attrs
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

  defp enough_funds?(%{"childchain_identifier" => _} = attrs) do
    attrs
    |> get_childchain_balance()
    |> process_balance_response(attrs)
  end

  defp enough_funds?(%{"rootchain_identifier" => _} = attrs) do
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

  defp set_blockchain(attrs), do: Map.put_new(attrs, "type", @external_transaction)

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

  defp submit_if_needed(%{blockchain_transaction_uuid: nil} = transaction, type, attrs) do
    with {:ok, blockchain_transaction} <- submit(transaction, attrs),
         {:ok, transaction} <-
           TransactionState.transition_to(
             type,
             TransactionState.blockchain_submitted(),
             transaction,
             %{blockchain_transaction_uuid: blockchain_transaction.uuid, originator: %System{}}
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

  defp submit_if_needed(transaction, _type, _attrs), do: {:ok, transaction}

  defp submit(
         %{type: @external_transaction} = transaction,
         %{
           "rootchain_identifier" => rootchain_identifier,
           "childchain_identifier" => childchain_identifier
         }
       ) do
    attrs = %{
      from: transaction.from_blockchain_address,
      to: transaction.to_blockchain_address,
      amount: transaction.from_amount,
      currency: transaction.from_token.blockchain_address
    }

    BlockchainTransactionGate.transfer_on_childchain(
      attrs,
      transaction,
      childchain_identifier,
      rootchain_identifier
    )
  end

  defp submit(%{type: @external_transaction} = transaction, %{
         "rootchain_identifier" => rootchain_identifier
       }) do
    attrs = %{
      from: transaction.from_blockchain_address,
      to: transaction.to_blockchain_address,
      amount: transaction.from_amount,
      currency: transaction.from_token.blockchain_address
    }

    BlockchainTransactionGate.transfer_on_rootchain(attrs, transaction, rootchain_identifier)
  end

  # TODO: Deposit transactions will be moved to a new `chidldchain_deposit_transaction` table.
  defp submit(%{type: @deposit_transaction} = transaction, %{
         "rootchain_identifier" => rootchain_identifier,
         "childchain_identifier" => childchain_identifier
       }) do
    attrs = %{
      amount: transaction.from_amount,
      currency: transaction.from_token.blockchain_address,
      to: transaction.from_blockchain_address
    }

    BlockchainTransactionGate.deposit_to_childchain(
      attrs,
      transaction,
      childchain_identifier,
      rootchain_identifier
    )
  end
end
