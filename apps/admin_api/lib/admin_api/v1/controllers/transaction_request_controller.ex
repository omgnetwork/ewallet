defmodule AdminAPI.V1.TransactionRequestController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.TransactionRequestPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}

  alias EWallet.{
    TransactionRequestGate,
    TransactionRequestFetcher
  }

  alias EWalletDB.{TransactionRequest, Account}

  @mapped_fields %{"created_at" => "inserted_at"}
  @preload_fields [:user, :account, :token, :wallet]
  @search_fields [:id, :status, :type, :correlation_id, :expiration_reason]
  @sort_fields [:id, :status, :type, :correlation_id, :inserted_at, :expired_at]

  @spec all(Plug.Conn.t(), map) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns),
         linked_user_uuids <-
           account_uuids |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      account_uuids
      |> TransactionRequest.query_all_for_account_and_user_uuids(linked_user_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         linked_user_uuids <-
           [account.uuid] |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      [account.uuid]
      |> TransactionRequest.query_all_for_account_and_user_uuids(linked_user_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account),
         linked_user_uuids <-
           descendant_uuids |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      descendant_uuids
      |> TransactionRequest.query_all_for_account_and_user_uuids(linked_user_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_account(conn, _) do
    handle_error(conn, :invalid_parameter, "Parameter 'id' is required.")
  end

  @spec do_all(Ecto.Queryable.t(), map(), Plug.Conn.t()) :: Plug.Conn.t()
  defp do_all(query, attrs, conn) do
    query
    |> Preloader.to_query(@preload_fields)
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @spec get(Plug.Conn.t(), map) :: Plug.Conn.t()
  def get(conn, %{"formatted_id" => formatted_id}) do
    with {:ok, request} <- TransactionRequestFetcher.get(formatted_id),
         :ok <- permit(:get, conn.assigns, request) do
      respond({:ok, request}, conn)
    else
      {:error, :transaction_request_not_found} ->
        respond({:error, :unauthorized}, conn)

      error ->
        respond(error, conn)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    attrs
    |> Map.put("creator", conn.assigns)
    |> TransactionRequestGate.create()
    |> respond(conn)
  end

  # Respond with a list of transaction requests
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

  @spec permit(
          :all | :create | :get | :update,
          map(),
          String.t() | %Account{} | %TransactionRequest{} | nil
        ) :: :ok | {:error, any()} | no_return()
  defp permit(action, params, request) do
    Bodyguard.permit(TransactionRequestPolicy, action, params, request)
  end
end
