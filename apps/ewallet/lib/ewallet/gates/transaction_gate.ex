defmodule EWallet.TransactionGate do
  @moduledoc """
  Handles the logic for a transaction of value from an account to a user. Delegates the
  actual transaction to EWallet.TransactionGate once the wallets have been loaded.
  """
  alias EWallet.{TransactionSourceFetcher, TransactionFormatter}
  alias EWalletDB.{Transaction, Token, Account}
  alias LocalLedger.Transaction, as: LedgerTransaction

  def create(%{"token_id" => token_id} = attrs) do
    with {:ok, from} <- TransactionSourceFetcher.fetch_from(attrs),
         {:ok, to} <- TransactionSourceFetcher.fetch_to(attrs),
         {:ok, from} <- TokenFetcher.fetch_from(attrs),
         {:ok, to} <- TokenFetcher.fetch_to(attrs),
         %Account{} = exchange_account <- Account.get(attrs["exchange_account_id"]) || :exchange_account_not_found,
         {:ok, transaction} <- get_or_insert(from, to, exchange_account, attrs) do
      process_with_transaction(transaction)
    else
      error when is_atom(error) -> {:ok, error}
      error -> error
    end
  end

  def create(_), do: {:error, :invalid_parameter}

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
    {:error, transaction, transaction.error_code, transaction.error_description || transaction.error_data}
  end

  def get_or_insert(
         from,
         to,
         exchange_account,
         %{
           "amount" => amount,
           "idempotency_token" => idempotency_token
         } = attrs
       ) do
    Transaction.get_or_insert(%{
      idempotency_token: idempotency_token,
      from_account: from[:from_account],
      from_user: from[:from_user],
      from_wallet: from.from_wallet,
      from_token: from.from_token,
      to_account: to[:to_account],
      to_user: to[:to_user],
      to_wallet: to.to_wallet,
      to_token: to.to_token,
      exchange_account: exchange_account,
      amount: amount,
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      payload: attrs,
      type: Transaction.internal()
    })
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
