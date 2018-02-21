defmodule EWalletAPI.V1.TransactionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias EWalletDB.{Transfer, User}

  plug :put_view, EWalletAPI.V1.TransactionView

  @preload_fields [:minted_token]
  @mapped_fields  %{"created_at" => "inserted_at"}
  @search_fields  [{:id, :uuid}, :idempotency_token, :status, :from, :to, :user_id]
  @sort_fields    [:id, :status, :from, :to, :inserted_at, :updated_at]

  # Server endpoint
  #
  # Helper action to get the list of all transactions for a specific user,
  # identified by a 'provider_user_id'.
  # Allows sorting, filtering and pagination.
  # This only retrieves the transactions related to the user's primary address. To get
  # the transactions for another address, use the `all` action.
  def all(conn, %{"provider_user_id" => provider_user_id} = attrs) do
    with %User{} = user <- User.get_by_provider_user_id(provider_user_id) ||
                           :provider_user_id_not_found
    do
      attrs
      |> user_transactions_search_terms(user)
      |> query_records_and_respond(conn)
    else
      error -> handle_error(conn, error)
    end
  end

  # Server endpoint
  #
  # Gets the list of ALL transactions.
  # Allows sorting, filtering and pagination.
  def all(conn, attrs), do: query_records_and_respond(attrs, conn)

  # Client endpoint
  #
  # Gets the list of transactions for the current logged in user.
  # Allows sorting, filtering and pagination.
  def get_transactions(%{assigns: %{user: user}} = conn, attrs) do
    attrs
    |> user_transactions_search_terms(user)
    |> query_records_and_respond(conn)
  end

  @doc """
  Retrieves a specific transaction by its id.
  """
  def get(conn, %{"id" => id}) do
    id
    |> Transfer.get(preload: @preload_fields)
    |> respond_single(conn)
  end
  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  defp user_transactions_search_terms(attrs, user) do
    balance = User.get_primary_balance(user)
    Map.put(attrs, "search_terms", %{"from" => balance.address, "to" => balance.address})
  end

  defp query_records_and_respond(attrs, conn) do
    Transfer
    |> Preloader.to_query(@preload_fields)
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  defp respond_multiple(%Paginator{} = paged_transactions, conn) do
    render(conn, :transactions, %{transactions: paged_transactions})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single(%Transfer{} = transaction, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end
  defp respond_single(nil, conn) do
    handle_error(conn, :transaction_id_not_found)
  end
end
