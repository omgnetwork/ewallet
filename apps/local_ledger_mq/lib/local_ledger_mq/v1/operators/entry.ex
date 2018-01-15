defmodule LocalLedgerMQ.V1.Operators.Entry do
  @moduledoc """
  Entry operator (similar to a web controller) receive and handles operations.
  """
  alias LocalLedgerMQ.ErrorHandler
  alias LocalLedgerMQ.V1.Serializers
  alias LocalLedgerMQ.V1.Serializers.Response

  @doc """
  Retrieve the list of all the entries in the database.
  TODO: Add filtering options.

  ## Payload

    {
      "operation": "entry.all"
    }

  """
  def operate("all", _attrs) do
    LocalLedger.Entry.all
    |> Enum.map(fn entry -> Serializers.Entry.serialize(entry) end)
    |> Serializers.List.serialize
    |> Serializers.Response.serialize(success: true)
  end

  @doc """
  Retrieve a specific entry based on its ID.

  ## Payload

    {
      "operation": "entry.get"
      "data": {
        "id": "123"
      }
    }

  ## Errors

    - invalid_uuid: the given id is not formatted as a UUID.
    - not_found: the record was not found in the database.

  """
  def operate("get", attrs) do
    case attrs["data"]["id"] do
      nil ->
        ErrorHandler.invalid_data()
      id ->
        id
        |> LocalLedger.Entry.get
        |> serialize
    end
  rescue
    Ecto.Query.CastError ->
      ErrorHandler.invalid_uuid(attrs["data"]["id"])
    Ecto.NoResultsError ->
      ErrorHandler.not_found(attrs["data"]["id"])
    exception ->
      reraise(exception, System.stacktrace)
  end

  @doc """
  Insert a new entry.

  ## Payload

    {
      "operation": "entry.insert"
      "data": {
        "metadata": {},
        "debits": [{"address": "123", "amount": 100, "metadata": {}}],
        "credits": [{"address": "456", "amount": 100, "metadata": {}}],
        "minted_token": {"friendly_id": "OMG:123", "metadata": {}}
      }
    }

  ## Errors

    - invalid_data: the submitted data doesn't follow the expected format.
    - correlation_id_conflict: an entry with the same correlation_id was found.
    - insufficient_funds: one of the debit balances did not have enough funds
      for the transaction.

  """
  def operate("insert", attrs) do
    operate("insert", attrs, false)
  end

  @doc """
  Insert a new genesis entry.

  ## Payload

    {
      "operation": "entry.genesis"
      "data": {
        "metadata": {},
        "debits": [{"address": "genesis", "amount": 100, "metadata": {}}],
        "credits": [{"address": "123", "amount": 100, "metadata": {}}],
        "minted_token": {"friendly_id": "OMG:123", "metadata": {}}
      }
    }

  ## Errors

    - invalid_data: the submitted data doesn't follow the expected format.
    - correlation_id_conflict: an entry with the same correlation_id was found.

  """
  def operate("genesis", attrs) do
    operate("insert", attrs, true)
  end

  def operate(_, attrs) do
    ErrorHandler.invalid_operation(attrs)
  end

  defp operate("insert", attrs, genesis) do
    entry =
      attrs["data"]
      |> Map.put("correlation_id", attrs["correlation_id"])
      |> LocalLedger.Entry.insert(genesis)

    case entry do
      {:ok, entry} ->
        serialize(entry)
      {:error, changeset} ->
        correlation_error = changeset.errors[:correlation_id]

        case correlation_error do
          nil ->
            ErrorHandler.invalid_data(changeset)
          _error ->
            changeset.changes.correlation_id
            |> LocalLedger.Entry.get_with_correlation_id
            |> serialize
        end
    end
  rescue
    e in LocalLedgerDB.Errors.InsufficientFundsError ->
      ErrorHandler.insufficient_funds(e)
    exception ->
      reraise(exception, System.stacktrace)
  end

  defp serialize(entry) do
    entry
    |> Serializers.Entry.serialize
    |> Response.serialize(success: true)
  end
end
