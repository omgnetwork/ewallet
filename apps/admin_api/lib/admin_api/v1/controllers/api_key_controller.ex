defmodule AdminAPI.V1.APIKeyController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.APIKey

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  # `@mapped_fields` don't affect them.
  @search_fields [:id, :key]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :key, :owner_app, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of API keys including soft-deleted.
  """
  def all(conn, attrs) do
    APIKey
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  # Respond with a list of API keys
  defp respond_multiple(%Paginator{} = paginated, conn) do
    render(conn, :api_keys, %{api_keys: paginated})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @doc """
  Creates a new API key. Currently API keys are assigned to the master account only.
  """
  def create(conn, _attrs) do
    # Admin API doesn't use API Keys anymore. Defaulting to :ewallet_api.
    %{owner_app: "ewallet_api"}
    |> APIKey.insert()
    |> respond_single(conn)
  end

  # Respond when the API key is saved successfully
  defp respond_single({:ok, api_key}, conn) do
    render(conn, :api_key, %{api_key: api_key})
  end

  # Responds when the API key is saved unsucessfully
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  @doc """
  Soft-deletes an existing API key by its id.
  """
  def delete(conn, %{"id" => id}) do
    with %APIKey{} = key <- APIKey.get(id) do
      do_delete(conn, key)
    else
      true ->
        handle_error(conn, :invalid_parameter, "The given API key is being used for this request")

      nil ->
        handle_error(conn, :api_key_not_found)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_delete(conn, %APIKey{} = key) do
    case APIKey.delete(key) do
      {:ok, _key} ->
        render(conn, :empty_response)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end
end
