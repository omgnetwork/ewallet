defmodule EWallet.TransactionGate do
  @moduledoc """
  Handles the logic for a transaction of value from an account to a user. Delegates the
  actual transaction to EWallet.TransactionGate once the wallets have been loaded.
  """
  alias EWallet.{
    AccountFetcher,
    AmountFetcher,
    TokenFetcher,
    TransactionFormatter,
    TransactionSourceFetcher
  }

  alias EWalletDB.{AccountUser, Transaction}
  alias ActivityLogger.System
  alias LocalLedger.Transaction, as: LedgerTransaction

  def create(attrs) do
    with {:ok, from} <- TransactionSourceFetcher.fetch_from(attrs),
         {:ok, to} <- TransactionSourceFetcher.fetch_to(attrs),
         {:ok, from, to} <- TokenFetcher.fetch(attrs, from, to),
         {:ok, from, to, exchange} <- AmountFetcher.fetch(attrs, from, to),
         {:ok, exchange} <- AccountFetcher.fetch_exchange_account(attrs, exchange),
         {:ok, transaction} <- get_or_insert(from, to, exchange, attrs),
         _ <- link(transaction) do
      process_with_transaction(transaction)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def process_with_transaction(%Transaction{status: "pending"} = transaction) do
    transaction
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: false})
    |> update_transaction(transaction)
    |> process_with_transaction()
  end

  def process_with_transaction(%Transaction{status: "confirmed"} = transaction) do
    {:ok, transaction}
  end

  def process_with_transaction(%Transaction{status: "failed"} = transaction) do
    {:error, transaction, transaction.error_code,
     transaction.error_description || transaction.error_data}
  end

  def get_or_insert(
        from,
        to,
        exchange,
        %{
          "idempotency_token" => idempotency_token
        } = attrs
      ) do
    Transaction.get_or_insert(%{
      originator: attrs["originator"],
      idempotency_token: idempotency_token,
      from_account_uuid: from[:from_account_uuid],
      from_user_uuid: from[:from_user_uuid],
      to_account_uuid: to[:to_account_uuid],
      to_user_uuid: to[:to_user_uuid],
      from: from.from_wallet_address,
      to: to.to_wallet_address,
      from_amount: from.from_amount,
      to_amount: to.to_amount,
      from_token_uuid: from.from_token.uuid,
      to_token_uuid: to.to_token.uuid,
      rate: exchange[:actual_rate],
      calculated_at: exchange[:calculated_at],
      exchange_pair_uuid: exchange[:pair_uuid],
      exchange_account_uuid: exchange[:exchange_account_uuid],
      exchange_wallet_address: exchange[:exchange_wallet_address],
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      payload: Map.delete(attrs, "originator"),
      type: Transaction.internal()
    })
  end

  def get_or_insert(_, _, _, _) do
    {:error, :invalid_parameter, "Invalid parameter provided. `idempotency_token` is required."}
  end

  def update_transaction(
        _,
        %Transaction{local_ledger_uuid: local_ledger_uuid, error_code: error_code} = transaction
      )
      when local_ledger_uuid != nil
      when error_code != nil do
    transaction
  end

  def update_transaction({:ok, ledger_transaction}, transaction) do
    Transaction.confirm(transaction, ledger_transaction.uuid, %System{})
  end

  def update_transaction({:error, code, description}, transaction) do
    Transaction.fail(transaction, code, description, %System{})
  end

  defp link(%Transaction{from_account_uuid: account_uuid, to_user_uuid: user_uuid} = transaction)
       when not is_nil(account_uuid) and not is_nil(user_uuid) do
    AccountUser.link(account_uuid, user_uuid, transaction)
  end

  defp link(%Transaction{from_user_uuid: user_uuid, to_account_uuid: account_uuid} = transaction)
       when not is_nil(account_uuid) and not is_nil(user_uuid) do
    AccountUser.link(account_uuid, user_uuid, transaction)
  end

  defp link(_), do: nil
end
