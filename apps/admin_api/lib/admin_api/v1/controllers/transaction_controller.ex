defmodule AdminAPI.V1.TransactionController do
  @moduledoc """
  The controller to serve transaction endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.TransactionGate
  alias EWallet.Web.{Paginator, Preloader, SearchParser, SortParser}
  alias EWallet.TransactionPolicy
  alias EWalletDB.{Account, Repo, Transaction, User}
  alias Ecto.Changeset

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that should be preloaded.
  # Note that these values *must be in the schema associations*.
  @preload_fields [:from_token, :to_token]

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
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      query_records_and_respond(Transaction, attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         linked_user_uuids <-
           [account.uuid] |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      [account.uuid]
      |> Transaction.all_for_account_and_user_uuids(linked_user_uuids)
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account),
         linked_user_uuids <-
           descendant_uuids |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      descendant_uuids
      |> Transaction.all_for_account_and_user_uuids(linked_user_uuids)
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Server endpoint

  Helper action to get the list of all transactions for a specific user,
  identified by a 'provider_user_id'.
  Allows sorting, filtering and pagination.
  This only retrieves the transactions related to the user's primary address. To get
  the transactions for another address, use the `all` action.

  The 'from' and 'to' fields cannot be searched for at the same
  time in the 'search_terms' param.
  """
  @spec all_for_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_user(conn, %{"user_id" => user_id} = attrs) do
    with %User{} = user <- User.get(user_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, user) do
      user
      |> Transaction.all_for_user()
      |> query_records_and_respond(attrs, conn)
    else
      error when is_atom(error) -> handle_error(conn, error)
      {:error, error} -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, %{"provider_user_id" => provider_user_id} = attrs) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, user) do
      user
      |> Transaction.all_for_user()
      |> query_records_and_respond(attrs, conn)
    else
      error when is_atom(error) -> handle_error(conn, error)
      {:error, error} -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves a specific transaction by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id}) do
    with :ok <- permit(:get, conn.assigns, id) do
      Transaction
      |> Preloader.to_query(@preload_fields)
      |> Repo.get_by(id: id)
      |> respond_single(conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Creates a transaction.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, attrs) do
      attrs
      |> TransactionGate.create()
      |> respond_single(conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  defp query_records_and_respond(query, attrs, conn) do
    query
    |> Preloader.to_query(@preload_fields)
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  # Respond with a list of transactions
  defp respond_multiple(%Paginator{} = paged_transactions, conn) do
    render(conn, :transactions, %{transactions: paged_transactions})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single transaction
  defp respond_single(%Transaction{} = transaction, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single({:ok, transaction}, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single({:error, _transaction, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond_single(nil, conn) do
    handle_error(conn, :transaction_id_not_found)
  end

  @spec permit(
          :all | :create | :get | :update,
          map(),
          String.t() | %Account{} | %User{} | map() | nil
        ) :: :ok | {:error, any()} | no_return()
  defp permit(action, params, data) do
    Bodyguard.permit(TransactionPolicy, action, params, data)
  end
end
