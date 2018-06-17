defmodule AdminAPI.V1.TransactionConsumptionController do
  use AdminAPI, :controller
  use EWallet.Web.Embedder
  import AdminAPI.V1.ErrorHandler

  alias EWallet.{
    Web.V1.Event,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionConfirmerGate
  }

  alias EWalletDB.TransactionConsumption

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  @embeddable [:account, :token, :transaction, :transaction_request, :user]

  # The fields in `@embeddable` that are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  @always_embed [:token]

  def consume(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    attrs
    |> TransactionConsumptionConsumerGate.consume()
    |> respond(conn)
  end

  def consume(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve(conn, attrs), do: confirm(conn, conn.assigns.key.account, attrs, true)
  def reject(conn, attrs), do: confirm(conn, conn.assigns.key.account, attrs, false)

  defp confirm(conn, entity, %{"id" => id}, approved) do
    id
    |> TransactionConsumptionConfirmerGate.confirm(approved, entity)
    |> respond(conn)
  end

  defp confirm(conn, _entity, _attrs, _approved), do: handle_error(conn, :invalid_parameter)

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)

  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
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
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end
end
