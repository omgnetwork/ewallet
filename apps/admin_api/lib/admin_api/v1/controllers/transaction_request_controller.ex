defmodule AdminAPI.V1.TransactionRequestController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.{
    TransactionRequestGate,
    TransactionRequestFetcher
  }

  @mapped_fields %{"created_at" => "inserted_at"}
  @preload_fields [:from_token, :to_token]
  @search_fields [:id, :idempotency_token, :status, :from, :to]
  @sort_fields [:id, :status, :from, :to, :inserted_at, :updated_at]

  def all(conn, attrs) do
    TransactionRequest
    |> Preloader.to_query(@preload_fields)
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  def create(conn, attrs) do
    attrs
    |> TransactionRequestGate.create()
    |> respond(conn)
  end

  def get(conn, %{"formatted_id" => formatted_id}) do
    formatted_id
    |> TransactionRequestFetcher.get()
    |> respond(conn)
  end

  # Respond with a list of transactions
  defp respond_multiple(%Paginator{} = paged_transaction_requests, conn) do
    render(conn, :transaction_requests, %{transaction_requests: paged_transaction_requests})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)

  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond({:ok, request}, conn) do
    render(conn, :transaction_request, %{
      transaction_request: request
    })
  end
end
