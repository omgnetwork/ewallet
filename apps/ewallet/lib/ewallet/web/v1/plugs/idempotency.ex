defmodule EWallet.Web.V1.Plug.Idempotency do
  @moduledoc """
  This plug extracts the value from the Idempotency-Token header.
  """
  import Plug.Conn
  import EWalletAPI.V1.ErrorHandler

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> parse_header()
    |> assign_token(conn)
  end

  defp parse_header(conn) do
    conn
    |> get_req_header("idempotency-token")
    |> List.first()
  end

  defp assign_token(nil, conn) do
    conn
    |> assign(:idempotency_token, nil)
    |> handle_error(:no_idempotency_token_provided)
  end

  defp assign_token(idempotency_token, conn) do
    assign(conn, :idempotency_token, idempotency_token)
  end
end
