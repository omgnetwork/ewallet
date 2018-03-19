defmodule EWalletAPI.V1.TransactionRequestConsumptionController do
  use EWalletAPI, :controller
  use EWallet.Web.Embedder
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.TransactionConsumptionGate

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  @embeddable [:account, :minted_token, :transaction, :transaction_request, :user]

  # The fields in `@embeddable` that are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  @always_embed [:minted_token]

  def consume(%{assigns: %{user: _}} = conn, attrs) do
    attrs = Map.put(attrs, "idempotency_token", conn.assigns.idempotency_token)

    conn.assigns.user
    |> TransactionConsumptionGate.consume(attrs)
    |> respond(conn)
  end

  def consume(%{assigns: %{account: _}} = conn, attrs) do
    attrs
    |> Map.put("idempotency_token", conn.assigns.idempotency_token)
    |> TransactionConsumptionGate.consume()
    |> respond(conn)
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:ok, consumption}, conn) do
    render(conn, :transaction_request_consumption, %{
      transaction_request_consumption: embed(consumption, conn.body_params["embed"])
    })
  end
end
