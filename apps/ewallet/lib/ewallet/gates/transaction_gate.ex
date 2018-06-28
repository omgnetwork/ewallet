defmodule EWallet.TransactionGate do
  @moduledoc """
  Handles the logic for a transaction of value from an account to a user. Delegates the
  actual transaction to EWallet.TransactionGate once the wallets have been loaded.
  """
  alias EWallet.{
    TransactionSourceFetcher,
    TokenFetcher,
    TransactionFormatter,
    AmountFetcher,
    AccountFetcher
  }

  alias EWalletDB.Transaction
  alias LocalLedger.Transaction, as: LedgerTransaction

  def create(attrs) do
    with {:ok, from} <- TransactionSourceFetcher.fetch_from(attrs),
         {:ok, to} <- TransactionSourceFetcher.fetch_to(attrs),
         {:ok, from, to} <- TokenFetcher.fetch(attrs, from, to),
         {:ok, from, to} <- AmountFetcher.fetch(attrs, from, to),
         {:ok, from} <- AccountFetcher.fetch_exchange_account(attrs, from),
         {:ok, transaction} <- get_or_insert(from, to, attrs) do
      process_with_transaction(transaction)
    else
      error when is_atom(error) -> {:ok, error}
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
        %{
          "idempotency_token" => idempotency_token
        } = attrs
      ) do
    Transaction.get_or_insert(%{
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
      rate: from[:actual_rate],
      calculated_at: from[:calculated_at],
      exchange_pair_uuid: from[:pair_uuid],
      exchange_account_uuid: from[:exchange_account_uuid],
      exchange_wallet_address: from[:exchange_wallet_address],
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      payload: attrs,
      type: Transaction.internal()
    })
  end

  def get_or_insert(_, _, _) do
    {:error, :invalid_parameter, "'idempotency_token' is required."}
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
    Transaction.confirm(transaction, ledger_transaction.uuid)
  end

  def update_transaction({:error, code, description}, transaction) do
    Transaction.fail(transaction, code, description)
  end
end
