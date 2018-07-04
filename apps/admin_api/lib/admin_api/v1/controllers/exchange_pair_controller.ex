defmodule AdminAPI.V1.ExchangePairController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{ExchangePairPolicy, UUIDFetcher}
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias EWalletDB.ExchangePair

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
  # If the request provides different names, map it via `@mapped_fields` first.
  @search_fields [:id, :name]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :name, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of exchange pairs.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      pairs =
        ExchangePair
        |> Preloader.to_query(@preload_fields)
        |> SearchParser.to_query(attrs, @search_fields, @mapped_fields)
        |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
        |> Paginator.paginate_attrs(attrs)

      case pairs do
        %Paginator{} = paginator ->
          render(conn, :exchange_pairs, %{exchange_pairs: paginator})

        {:error, code, description} ->
          handle_error(conn, code, description)
      end
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Retrieves a specific exchange pair by its id.
  """
  def get(conn, %{"id" => id}) do
    with :ok <- permit(:get, conn.assigns, id),
         %ExchangePair{} = pair <- ExchangePair.get_by(id: id),
         {:ok, pair} <- Preloader.preload_one(pair, @preload_fields) do
      render(conn, :exchange_pair, %{exchange_pair: pair})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :exchange_pair_id_not_found)
    end
  end

  @doc """
  Creates a new exchange pair.
  """
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         %{} = attrs <- UUIDFetcher.replace_external_ids(attrs),
         {:ok, pair} <- ExchangePair.insert(attrs),
         {:ok, pair} <- Preloader.preload_one(pair, @preload_fields) do
      render(conn, :exchange_pair, %{exchange_pair: pair})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates the exchange pair if all required parameters are provided.
  """
  def update(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:update, conn.assigns, id),
         %{} = attrs <- UUIDFetcher.replace_external_ids(attrs),
         %ExchangePair{} = pair <- ExchangePair.get(id) || {:error, :exchange_pair_id_not_found},
         {:ok, updated} <- ExchangePair.update(pair, attrs),
         {:ok, updated} <- Preloader.preload_one(updated, @preload_fields) do
      render(conn, :exchange_pair, %{exchange_pair: updated})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Soft-deletes an existing exchange pair by its id.
  """
  def delete(conn, %{"id" => id}) do
    with %ExchangePair{} = pair <- ExchangePair.get(id) || {:error, :exchange_pair_id_not_found},
         {:ok, deleted} = ExchangePair.delete(pair),
         {:ok, deleted} <- Preloader.preload_one(deleted, @preload_fields) do
      render(conn, :exchange_pair, %{exchange_pair: deleted})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec permit(:all | :create | :get | :update, map(), String.t()) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, exchange_pair_id) do
    Bodyguard.permit(ExchangePairPolicy, action, params, exchange_pair_id)
  end
end
