defmodule AdminAPI.V1.TransactionController do
  @moduledoc """
  The controller to serve transaction endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias EWalletDB.{Repo, Transfer}

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that should be preloaded.
  # Note that these values *must be in the schema associations*.
  @preload_fields [:token]

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  # `@mapped_fields` don't affect them.
  @search_fields [:id, :idempotency_token, :status, :from, :to]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :status, :from, :to, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of transactions.
  """
  def all(conn, attrs) do
    Transfer
    |> Preloader.to_query(@preload_fields)
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific transaction by its id.
  """
  def get(conn, %{"id" => id}) do
    Transfer
    |> Preloader.to_query(@preload_fields)
    |> Repo.get_by(id: id)
    |> respond_single(conn)
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Creates a transaction.
  """
  def create(
        conn,
        %{
          "from_address" => from_address,
          "to_address" => to_address,
          "token_id" => token_id,
          "amount" => amount
        } = attrs
      )
      when from_address != nil
      when to_address != nil and token_id != nil and is_integer(amount) do
    attrs
    |> Map.put("idempotency_token", conn.assigns[:idempotency_token])
    |> TransactionGate.process_with_addresses()
    |> respond_single(conn)
  end

  # Respond with a list of transactions
  defp respond_multiple(%Paginator{} = paged_transactions, conn) do
    render(conn, :transactions, %{transactions: paged_transactions})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single transaction
  defp respond_single(%Transfer{} = transaction, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single(nil, conn) do
    handle_error(conn, :transaction_id_not_found)
  end
end
