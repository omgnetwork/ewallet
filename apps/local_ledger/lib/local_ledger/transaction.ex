defmodule LocalLedger.Transaction do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schemas and contains the logic
  needed to insert valid transactions and entries.
  """
  alias LocalLedgerDB.{Repo, Transaction, Errors.InsufficientFundsError}

  alias LocalLedger.{
    Entry,
    Wallet,
    Errors.InvalidAmountError,
    Errors.AmountIsZeroError
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
    - AmountIsZeroError: This error will be raised if any of the provided amount is equal to 0.

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
          "debits" => debits,
          "credits" => credits,
          "idempotency_token" => idempotency_token
        },
        %{genesis: genesis},
        callback \\ nil
      ) do
    {debits, credits}
    |> Validator.validate_zero_sum()
    |> Validator.validate_positive_amounts()
    |> Entry.build_all()
    |> locked_insert(metadata, idempotency_token, genesis, callback)
  rescue
    e in InsufficientFundsError ->
      {:error, :insufficient_funds, e.message}

    e in InvalidAmountError ->
      {:error, :invalid_amount, e.message}

    e in AmountIsZeroError ->
      {:error, :amount_is_zero, e.message}
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
