defmodule AdminAPI.V1.KeyController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
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
  Retrieves a list of keys.
  """
  def all(conn, attrs) do
    Key
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  # Respond with a list of keys
  defp respond_multiple(%Paginator{} = paginated_keys, conn) do
    render(conn, :keys, %{keys: paginated_keys})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
end
