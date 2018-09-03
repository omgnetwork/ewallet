defmodule EWalletAPI.V1.TransactionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{TransactionGate, WalletFetcher}
  alias EWallet.Web.{Paginator, Preloader, SearchParser, SortParser}
  alias EWalletDB.{Repo, Transaction, User}

  @preload_fields [:from_token, :to_token]
  @mapped_fields %{"created_at" => "inserted_at"}
  @search_fields [:id, :idempotency_token, :status, :from, :to]
  @sort_fields [:id, :status, :from, :to, :inserted_at, :updated_at]
  @allowed_fields [
    "idempotency_token",
    "from_address",
    "to_address",
    "to_account_id",
    "to_provider_user_id",
    "token_id",
    "amount",
    "metadata",
    "encrypted_metadata"
  ]

  @doc """
  Server endpoint

  Gets the list of ALL transactions.
  Allows sorting, filtering and pagination.
  """
  def all(conn, attrs), do: query_records_and_respond(Transaction, attrs, conn)

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
  def all_for_user(conn, %{"provider_user_id" => provider_user_id} = attrs) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(user, attrs["address"]) do
      attrs = clean_address_search_terms(user, attrs)

      wallet.address
      |> Transaction.all_for_address()
      |> query_records_and_respond(attrs, conn)
    else
      error when is_atom(error) -> handle_error(conn, error)
      {:error, error} -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Client endpoint

  Gets the list of transactions for the current logged in user.
  Allows sorting, filtering and pagination.

  The 'from' and 'to' fields cannot be searched for at the same
  time in the 'search_terms' param.
  """
  def get_transactions(%{assigns: %{user: user}} = conn, attrs) do
    with {:ok, wallet} <- WalletFetcher.get(user, attrs["address"]) do
      attrs =
        user
        |> Repo.preload([:wallets])
        |> clean_address_search_terms(attrs)

      wallet.address
      |> Transaction.all_for_address()
      |> query_records_and_respond(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def create(conn, attrs) do
    attrs
    |> Enum.filter(fn {k, _v} -> Enum.member?(@allowed_fields, k) end)
    |> Enum.into(%{})
    |> Map.put("from_user_id", conn.assigns.user.id)
    |> TransactionGate.create()
    |> respond(conn)
  end

  defp clean_address_search_terms(user, %{"search_terms" => terms} = attrs) do
    addresses = User.addresses(user)

    terms
    |> contains_illegal_from_and_to?()
    |> remove_illegal_params_if_present(attrs, addresses)
  end

  defp clean_address_search_terms(_user, attrs), do: attrs

  defp contains_illegal_from_and_to?(terms) do
    !is_nil(terms["from"]) && !is_nil(terms["to"])
  end

  defp remove_illegal_params_if_present(true, %{"search_terms" => terms} = attrs, addresses) do
    from_member? = Enum.member?(addresses, terms["from"])
    to_member? = Enum.member?(addresses, terms["to"])

    case {from_member?, to_member?} do
      {false, false} ->
        terms =
          terms
          |> Map.delete("from")
          |> Map.delete("to")

        Map.put(attrs, "search_terms", terms)

      _ ->
        attrs
    end
  end

  defp remove_illegal_params_if_present(false, attrs, _addresses), do: attrs

  defp query_records_and_respond(query, attrs, conn) do
    query
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

  defp respond({:ok, transaction}, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:error, code}, conn), do: handle_error(conn, code)

  defp respond({:error, _transaction, code, description}, conn) do
    handle_error(conn, code, description)
  end
end
