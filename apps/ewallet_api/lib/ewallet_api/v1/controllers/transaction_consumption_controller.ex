defmodule EWalletAPI.V1.TransactionConsumptionController do
  use EWalletAPI, :controller
  use EWallet.Web.Embedder
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{Web.V1.Event, TransactionConsumptionGate}

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  @embeddable [:account, :minted_token, :transaction, :transaction_request, :user]

  # The fields in `@embeddable` that are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  @always_embed [:minted_token]

  def consume(conn, attrs) do
    attrs
    |> Map.put("idempotency_token", conn.assigns.idempotency_token)
    |> TransactionConsumptionGate.consume()
    |> respond(conn)
  end

  def consume_for_user(conn, attrs) do
    attrs = Map.put(attrs, "idempotency_token", conn.assigns.idempotency_token)

    conn.assigns.user
    |> TransactionConsumptionGate.consume(attrs)
    |> respond(conn)
  end

  def approve(conn, attrs), do: confirm(conn, conn.assigns.account, attrs, true)
  def reject(conn, attrs), do: confirm(conn, conn.assigns.account, attrs, false)
  def approve_for_user(conn, attrs), do: confirm(conn, conn.assigns.user, attrs, true)
  def reject_for_user(conn, attrs), do: confirm(conn, conn.assigns.user, attrs, false)

  defp confirm(conn, entity, %{"id" => id}, approved) do
    id
    |> TransactionConsumptionGate.confirm(approved, entity)
    |> respond(conn)
  end
  defp confirm(conn, _attrs, _approved), do: handle_error(conn, :invalid_parameter)

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:error, consumption, code, description}, conn) do
    dispatch_confirm_event(consumption)
    handle_error(conn, code, description)
  end
  defp respond({:ok, consumption}, conn) do
    dispatch_confirm_event(consumption)
    render(conn, :transaction_consumption, %{
      transaction_consumption: embed(consumption, conn.body_params["embed"])
    })
  end

  defp dispatch_confirm_event(consumption) do
    if consumption.finalized_at do
      case consumption.approved do
        true ->
          Event.dispatch(:transaction_consumption_approved, %{consumption: consumption})
        false ->
          Event.dispatch(:transaction_consumption_rejected, %{consumption: consumption})
      end
    end
  end
end
