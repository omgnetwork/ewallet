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

defmodule LocalLedger.Transaction do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schemas and contains the logic
  needed to insert valid transactions and entries.
  """
  alias LocalLedgerDB.{Errors.InsufficientFundsError, Repo, Transaction, Entry}
  alias LocalLedgerDB.Entry, as: EntrySchema

  alias LocalLedger.{
    CachedBalance,
    Entry,
    Errors.AmountNotPositiveError,
    Errors.InvalidAmountError,
    Errors.SameAddressError,
    Wallet
  }

  alias LocalLedger.Transaction.Validator

  @doc """
  Retrieve all transactions from the database.
  """
  @spec all() :: {:ok, [%Transaction{}]}
  def all do
    {:ok, Transaction.all()}
  end

  @doc """
  Retrieve a specific transaction from the database.
  """
  @spec get(String.t()) :: {:ok, %Transaction{} | nil}
  def get(id) do
    {:ok, Transaction.one(id)}
  end

  @doc """
  Retrieve a specific transaction based on a correlation ID from the database.
  """
  @spec get_by_idempotency_token(String.t()) :: {:ok, %Transaction{} | nil}
  def get_by_idempotency_token(idempotency_token) do
    {:ok, Transaction.get_by_idempotency_token(idempotency_token)}
  end

  @doc """
  Insert a new transaction and the associated entries. If they are not already
  present, a new token and new wallets will be created.

  ## Parameters

    - attrs: a map containing the following keys
      - metadata: a map containing metadata for this transaction
      - debits: a list of debit entries to process (see example)
      - credits: a list of credit entries to process (see example)
      - token: the token associated with this transaction
    - genesis (boolean, default to false): if set to true, this argument will
      allow the debit wallets to go into the negative.

  ## Errors

    - InsufficientFundsError: This error will be raised if a debit is requested
      from an address which does not have enough funds.
    - InvalidAmountError: This error will be raised if the sum of all debits
      and credits in this transaction is not equal to 0.
    - AmountNotPositiveError: This error will be raised if any of the provided amount
      is less than or equal to 0.

  ## Examples

      Transaction.insert(%{
        metadata: %{},
        debits: [%{
          address: "an_address",
          amount: 100,
          metadata: %{}
        }],
        credits: [%{
          address: "another_address",
          amount: 100,
          metadata: %{}
        }],
        idempotency_token: "123"
      })
  """
  @spec insert(map(), map(), fun() | nil) :: {:ok, %Transaction{}} | {:error, Ecto.Changeset.t()}
  def insert(
        %{
          "metadata" => metadata,
          "entries" => entries,
          "idempotency_token" => idempotency_token
        },
        %{genesis: genesis} = opts,
        callback \\ nil
      ) do
    entries
    |> Validator.validate_different_addresses()
    |> Validator.validate_positive_amounts()
    |> Validator.validate_zero_sum()
    |> Entry.build_all(opts)
    |> locked_insert(metadata, idempotency_token, genesis, callback, opts)
  rescue
    e in SameAddressError ->
      {:error, :same_address, e.message}

    e in AmountNotPositiveError ->
      {:error, :amount_is_zero, e.message}

    e in InvalidAmountError ->
      {:error, :invalid_amount, e.message}

    e in InsufficientFundsError ->
      {:error, :insufficient_funds, e.message}
  end

  @doc """
  Marks the transaction and its entries as confirmed.
  """
  @spec confirm(String.t()) :: {:ok, %Transaction{}} | {:error, Ecto.Changeset.t()}
  def confirm(transaction_uuid) do
    with %Transaction{} = transaction <-
           Transaction.get_by(%{uuid: transaction_uuid}, preload: [:entries]) do
      flagged_entries =
        Enum.map(transaction.entries, fn entry ->
          %{
            uuid: entry.uuid,
            status: EntrySchema.confirmed()
          }
        end)

      Transaction.update(transaction, %{
        status: Transaction.confirmed(),
        entries: flagged_entries
      })
    end
  end

  @doc """
  Marks the transaction and its entries as failed.

  This operation will also delete the cached balances since the failed transaction.
  """
  @spec fail(String.t()) :: {:ok, %Transaction{}} | {:error, Ecto.Changeset.t()}
  def fail(transaction_uuid) do
    with %Transaction{} = transaction <-
           Transaction.get_by(%{uuid: transaction_uuid}, preload: [entries: [:wallet]]) do
      flagged_entries =
        Enum.map(transaction.entries, fn entry ->
          %{
            uuid: entry.uuid,
            status: EntrySchema.failed()
          }
        end)

      result =
        Transaction.update(transaction, %{
          status: Transaction.failed(),
          entries: flagged_entries
        })

      _ =
        case result do
          {:ok, _} ->
            # A transaction is inserted before entries, so deleting since transaction.insert_at
            # should cover all its entries just fine.
            transaction.entries
            |> Enum.map(fn e -> e.wallet end)
            |> Enum.uniq()
            |> CachedBalance.delete_since(transaction.inserted_at)

          _ ->
            :noop
        end

      result
    end
  end

  # Lock all the DEBIT addresses to ensure the truthness of the wallets
  # amounts, before inserting one transaction and the associated entries.
  # If the genesis argument is passed as true, the balance check will be
  # skipped.
  defp locked_insert(entries, metadata, idempotency_token, genesis, callback, opts) do
    addresses = Entry.get_addresses(entries)

    Wallet.lock(addresses, fn ->
      if callback, do: callback.()

      Entry.check_balance(entries, %{genesis: genesis})

      %{
        idempotency_token: idempotency_token,
        entries: entries,
        metadata: metadata,
        status: opts[:status] || Transaction.confirmed()
      }
      |> Transaction.get_or_insert()
      |> case do
        {:ok, transaction} ->
          transaction

        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end
