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
  alias LocalLedgerDB.{Errors.InsufficientFundsError, Repo, Transaction}

  alias LocalLedger.{
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
  def all do
    {:ok, Transaction.all()}
  end

  @doc """
  Retrieve a specific transaction from the database.
  """
  def get(id) do
    {:ok, Transaction.one(id)}
  end

  @doc """
  Retrieve a specific transaction based on a correlation ID from the database.
  """
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
  def insert(
        %{
          "metadata" => metadata,
          "entries" => entries,
          "idempotency_token" => idempotency_token
        },
        %{genesis: genesis},
        callback \\ nil
      ) do
    entries
    |> Validator.validate_different_addresses()
    |> Validator.validate_positive_amounts()
    |> Validator.validate_zero_sum()
    |> Entry.build_all()
    |> locked_insert(metadata, idempotency_token, genesis, callback)
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

  # Lock all the DEBIT addresses to ensure the truthness of the wallets
  # amounts, before inserting one transaction and the associated entries.
  # If the genesis argument is passed as true, the balance check will be
  # skipped.
  defp locked_insert(entries, metadata, idempotency_token, genesis, callback) do
    addresses = Entry.get_addresses(entries)

    Wallet.lock(addresses, fn ->
      if callback, do: callback.()

      Entry.check_balance(entries, %{genesis: genesis})

      %{
        idempotency_token: idempotency_token,
        entries: entries,
        metadata: metadata
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
