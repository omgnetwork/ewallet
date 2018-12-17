defmodule EWallet.GenesisGate do
  @moduledoc """
  Handle Genesis transactions.
  """
  alias EWallet.{TransactionFormatter, TransactionGate}
  alias EWalletDB.{Account, Mint, Transaction, Wallet}
  alias LocalLedger.Transaction, as: LedgerTransaction

  def create(%{
        idempotency_token: idempotency_token,
        account: account,
        token: token,
        amount: amount,
        attrs: attrs,
        originator: originator
      }) do
    Transaction.get_or_insert(%{
      idempotency_token: idempotency_token,
      from: Wallet.get_genesis().address,
      to: Account.get_primary_wallet(account).address,
      to_account_uuid: account.uuid,
      from_token_uuid: token.uuid,
      to_token_uuid: token.uuid,
      from_amount: amount,
      to_amount: amount,
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      payload: Map.delete(attrs, "originator"),
      originator: originator
    })
  end

  @spec process_with_transaction(%Transaction{}, %Mint{}) ::
          {:ok, %Mint{}, %Transaction{}} | {:error, atom(), String.t(), %Mint{}}

  def process_with_transaction(%Transaction{status: "pending"} = transaction, mint) do
    transaction
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: true})
    |> TransactionGate.update_transaction(transaction)
    |> confirm_and_return(mint)
  end

  def process_with_transaction(%Transaction{status: "confirmed"} = transaction, mint) do
    confirm_and_return(transaction, mint)
  end

  def process_with_transaction(%Transaction{status: "failed"} = transaction, mint) do
    confirm_and_return(
      {:error, transaction.error_code, transaction.error_description || transaction.error_data},
      mint
    )
  end

  defp confirm_and_return({:error, code, description}, mint),
    do: {:error, code, description, mint}

  defp confirm_and_return(transaction, mint) do
    mint = Mint.confirm(mint, transaction)
    {:ok, mint, transaction}
  end
end
