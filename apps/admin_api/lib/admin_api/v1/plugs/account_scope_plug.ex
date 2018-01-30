defmodule AdminAPI.V1.AccountScopePlug do
  @moduledoc """
  This plug extracts the account's scope from the request header,
  and assigns it to the connection as `scoped_account_id` for downstream usage.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias Ecto.UUID

  def init(opts), do: opts

  def call(conn, _opts) do
    parse_header(conn)
  end

  defp parse_header(conn) do
    header =
      conn
      |> get_req_header("omgadmin-account-id")
      |> List.first()

    with header when not is_nil(header) <- header,
         {:ok, uuid} when is_binary(uuid) <- UUID.cast(header) do
      assign(conn, :scoped_account_id, uuid)
    else
      # If the header is provided, it must be a UUID
      :error -> handle_error(conn, :invalid_account_id)
      # If the header is not provided, this plug does nothing
      nil -> conn
    end
  end
end
