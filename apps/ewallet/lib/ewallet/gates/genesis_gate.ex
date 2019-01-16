# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.GenesisGate do
  @moduledoc """
  Handle Genesis transactions.
  """
  alias EWallet.{TransactionFormatter, TransactionGate}
  alias EWalletDB.{Account, Mint, Transaction, Wallet}
  alias LocalLedger.Transaction, as: LedgerTransaction

  @doc """
  Get the genesis transaction by the idempotency_token, or create a new transaction
  if the idempotency_token could not be found.
  """
  @spec create(map()) :: {:ok, %Transaction{}} | {:error, Ecto.Changeset.t()}
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

  @doc """
  Processes the genesis transaction with the mint.

  If the `transaction`'s status is pending, it inserts a corresponding `LocalLedgerDB.Transaction`,
  and, on success, returns an `EWalletDB.Transaction` with a confirmed status along with
  a confirmed `EWalletDB.Mint`.

  If the `transaction`'s status is already confirmed, it returns the transaction untouched, while
  still attempting to confirm the given `mint`.

  If the `transaction`'s status is already failed, it returns the transaction's error code and
  error description. It does not attempt to confirm the given `mint`.
  """
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
