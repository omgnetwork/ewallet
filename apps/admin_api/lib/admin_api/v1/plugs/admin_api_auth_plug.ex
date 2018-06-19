defmodule AdminAPI.V1.AdminAPIAuthPlug do
  @moduledoc """
  This module is responsible for dispatching the authentication of the given
  request to the appropriate authentication plug based on the provided scheme.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AdminAPIAuth

  def init(opts), do: opts

  def call(conn, _opts) do
    %{http_headers: conn.req_headers}
    |> AdminAPIAuth.authenticate()
    |> handle_auth_result(conn)
  end

  defp handle_auth_result(%{authenticated: false} = auth, conn) do
    conn
    |> assign(:authenticated, false)
    |> handle_error(auth[:auth_error])
  end

  defp handle_auth_result(
         %{authenticated: true, auth_scheme: :admin, admin_user: admin_user} = auth,
         conn
       ) do
    conn
    |> assign(:authenticated, true)
    |> assign(:auth_scheme, :admin)
    |> assign(:admin_user, admin_user)
    |> put_private(:auth_user_id, auth[:auth_user_id])
    |> put_private(:auth_auth_token, auth[:auth_auth_token])
  end

  defp handle_auth_result(%{authenticated: true, auth_scheme: :provider, key: key} = auth, conn) do
    conn
    |> assign(:authenticated, true)
    |> assign(:auth_scheme, :provider)
    |> assign(:key, key)
    |> put_private(:auth_access_key, auth[:auth_access_key])
    |> put_private(:auth_secret_key, auth[:auth_secret_key])
  end
end
