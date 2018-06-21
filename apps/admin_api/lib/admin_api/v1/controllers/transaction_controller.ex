defmodule AdminAPI.V1.TransactionController do
  @moduledoc """
  The controller to serve transaction endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.TransactionGate
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias EWallet.WalletFetcher
  alias EWalletDB.{Repo, Transaction, User}

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
  # def all(conn, attrs) do
  #   Transaction
  #   |> Preloader.to_query(@preload_fields)
  #   |> SearchParser.to_query(attrs, @search_fields)
  #   |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
  #   |> Paginator.paginate_attrs(attrs)
  #   |> respond_multiple(conn)
  # end

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
  Retrieves a specific transaction by its id.
  """
  def get(conn, %{"id" => id}) do
    Transaction
    |> Preloader.to_query(@preload_fields)
    |> Repo.get_by(id: id)
    |> respond_single(conn)
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Creates a transaction.
  """
  def create(conn, attrs) do
    attrs
    |> TransactionGate.create()
    |> respond_single(conn)
  end

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

  defp clean_address_search_terms(user, %{"search_terms" => terms} = attrs) do
    addresses = User.addresses(user)

    terms
    |> contains_illegal_from_and_to?()
    |> remove_illegal_params_if_present(attrs, addresses)
  end

  defp clean_address_search_terms(_user, attrs), do: attrs

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

  defp respond_single({:ok, transaction, _wallets, _token}, conn) do
    render(conn, :transaction, %{transaction: transaction})
  end

  defp respond_single({:error, _transaction, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond_single(nil, conn) do
    handle_error(conn, :transaction_id_not_found)
  end
end
