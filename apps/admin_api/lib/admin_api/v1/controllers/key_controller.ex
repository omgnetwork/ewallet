defmodule AdminAPI.V1.KeyController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.KeyPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.Key

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
  @search_fields [:access_key]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:access_key, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of keys including soft-deleted.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns) do
      Key
      |> Key.all_for_account_uuids(account_uuids)
      |> SearchParser.to_query(attrs, @search_fields)
      |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
      |> Paginator.paginate_attrs(attrs)
      |> respond_multiple(conn)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  # Respond with a list of keys
  defp respond_multiple(%Paginator{} = paginated_keys, conn) do
    render(conn, :keys, %{keys: paginated_keys})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @doc """
  Creates a new key. Currently keys are assigned to the master account only.
  """
  def create(conn, _attrs) do
    with :ok <- permit(:create, conn.assigns, nil) do
      %{}
      |> Key.insert()
      |> respond_single(conn)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  # Respond when the key is saved successfully
  defp respond_single({:ok, key}, conn) do
    render(conn, :key, %{key: key})
  end

  # Responds when the key is saved unsucessfully
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  @doc """
  Soft-deletes an existing key.
  """
  def delete(conn, %{"access_key" => access_key}) do
    with :ok <- permit(:delete, conn.assigns, nil) do
      key = Key.get(:access_key, access_key)
      do_delete(conn, key)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- permit(:delete, conn.assigns, nil) do
      key = Key.get(id)
      do_delete(conn, key)
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_delete(conn, %Key{} = key) do
    case Key.delete(key) do
      {:ok, _key} ->
        render(conn, :empty_response)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  defp do_delete(conn, nil), do: handle_error(conn, :key_not_found)

  @spec permit(:all | :create | :get | :update, map(), String.t()) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, key_id) do
    Bodyguard.permit(KeyPolicy, action, params, key_id)
  end
end
