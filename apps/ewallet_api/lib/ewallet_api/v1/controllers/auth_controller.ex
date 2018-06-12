defmodule EWalletAPI.V1.AuthController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWalletDB.{AuthToken, User}
  alias EWalletAPI.V1.Plug.ClientAuth

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    conn
    |> ClientAuth.expire_token()
    |> respond()
  end

  defp respond({:ok, token}, conn), do: render(conn, :auth_token, %{auth_token: token})
  defp respond({:error, code}, conn), do: handle_error(conn, code)
  defp respond(conn), do: render(conn, :empty_response, %{})
end
