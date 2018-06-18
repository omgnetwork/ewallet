defmodule EWalletAPI.V1.AuthController do
  use EWalletAPI, :controller
  alias EWalletAPI.V1.Plug.ClientAuthPlug

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    conn
    |> ClientAuthPlug.expire_token()
    |> respond()
  end

  defp respond(conn), do: render(conn, :empty_response, %{})
end
