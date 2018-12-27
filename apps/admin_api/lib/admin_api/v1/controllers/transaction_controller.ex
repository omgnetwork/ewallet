defmodule AdminAPI.V1.TransactionController do
  @moduledoc """
  The controller to serve transaction endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias Ecto.Changeset
  alias EWallet.{TransactionPolicy, TransactionGate, ExportGate}

  alias EWallet.Web.{
    Originator,
    Preloader,
    Orchestrator,
    Paginator,
    V1.TransactionOverlay,
    V1.ExportOverlay,
    V1.CSV.TransactionSerializer
  }

  alias EWalletDB.{Account, Repo, Transaction, User, Export}

  @doc """
  Creates an export transactions.
  """
  @spec export(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def export(conn, attrs) do
    with :ok <- permit(:export, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns),
         attrs = Originator.set_in_attrs(attrs, conn.assigns, :originator) do
      Transaction
      |> Transaction.query_all_for_account_uuids_and_users(account_uuids)
      |> Orchestrator.build_query(TransactionOverlay, attrs)
      |> ExportGate.export("transaction", TransactionSerializer, attrs)
      |> respond_single(conn)
    else
      {:error, error} ->
        handle_error(conn, error)
    end
  end

  @doc """
  Retrieves a list of transactions.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns) do
      Transaction
      |> Transaction.query_all_for_account_uuids_and_users(account_uuids)
      |> query_records_and_respond(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account) do
      Transaction
      |> Transaction.query_all_for_account_uuids_and_users([account.uuid])
      |> query_records_and_respond(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      Transaction
      |> Transaction.query_all_for_account_uuids_and_users(descendant_uuids)
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
  def get(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:get, conn.assigns, id) do
      Transaction
      |> Orchestrator.preload_to_query(TransactionOverlay, attrs)
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
    with :ok <- permit(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, transaction} <- TransactionGate.create(attrs) do
      transaction
      |> Orchestrator.one(TransactionOverlay, attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  defp query_records_and_respond(query, attrs, conn) do
    query
    |> Orchestrator.query(TransactionOverlay, attrs)
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

  defp respond_single({:ok, %Transaction{} = transaction}, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single({:ok, %Export{} = export}, conn) do
    {:ok, export} = Preloader.preload_one(export, ExportOverlay.default_preload_assocs())
    render(conn, :export, %{export: export})
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
