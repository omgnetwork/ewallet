defmodule LocalLedger.Entry do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schemas and contains the logic
  needed to insert valid entries and transactions.
  """
  alias LocalLedgerDB.{Repo, Entry, Errors.InsufficientFundsError}
  alias LocalLedger.{Transaction, Balance, Errors.InvalidAmountError, Errors.AmountIsZeroError}
  alias LocalLedger.Entry.Validator

  @doc """
  Retrieve all entries from the database.
  """
  def all do
    {:ok, Entry.all}
  end

  @doc """
  Retrieve a specific entry from the database.
  """
  def get(id) do
    {:ok, Entry.one(id)}
  end

  @doc """
  Retrieve a specific entry based on a correlation ID from the database.
  """
  def get_with_correlation_id(correlation_id) do
    {:ok, Entry.get_with_correlation_id(correlation_id)}
  end

  @doc """
  Insert a new entry and the associated transactions. If they are not already
  present, a new minted token and new balances will be created.

  ## Parameters

    - attrs: a map containing the following keys
      - metadata: a map containing metadata for this entry
      - debits: a list of debit transactions to process (see example)
      - credits: a list of credit transactions to process (see example)
      - minted_token: the token associated with this entry
    - genesis (boolean, default to false): if set to true, this argument will
      allow the debit balances to go into the negative.

  ## Errors

    - InsufficientFundsError: This error will be raised if a debit is requested
      from an address which does not have enough funds.
    - InvalidAmountError: This error will be raised if the sum of all debits
      and credits in this entry is not equal to 0.
    - AmountIsZeroError: This error will be raised if any of the provided amount is equal to 0.

  ## Examples

      Entry.insert(%{
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
        minted_token: %{
          friendly_id: "OMG:123",
          metadata: %{}
        },
        correlation_id: "123"
      })

  """
  def insert(%{"metadata" => metadata, "debits" => debits, "credits" => credits,
               "minted_token" => minted_token, "correlation_id" => correlation_id},
               %{genesis: genesis}, callback \\ nil) do
    {debits, credits}
    |> Validator.validate_zero_sum()
    |> Validator.validate_positive_amounts()
    |> Transaction.build_all(minted_token)
    |> locked_insert(metadata, correlation_id, genesis, callback)
  rescue
    e in InsufficientFundsError ->
      {:error, "transaction:insufficient_funds", e.message}
    e in InvalidAmountError ->
      {:error, "transaction:invalid_amount", e.message}
    e in AmountIsZeroError ->
      {:error, "transaction:amount_is_zero", e.message}
  end

  # Lock all the DEBIT addresses to ensure the truthness of the balances
  # amounts, before inserting one entry and the associated transactions.
  # If the genesis argument is passed as true, the balance check will be
  # skipped.
  defp locked_insert(transactions, metadata, correlation_id, genesis, callback) do
    addresses = Transaction.get_addresses(transactions)

    Balance.lock(addresses, fn ->
      if callback, do: callback.()

      Transaction.check_balance(transactions, %{genesis: genesis})
      changes = %{
        correlation_id: correlation_id,
        transactions: transactions,
        metadata: metadata
      }

      case Entry.insert(changes) do
        {:ok, entry} ->
          entry
        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end
end
