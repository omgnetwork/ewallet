defmodule EWalletAPI.V1.TransactionConsumptionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.{Orchestrator, V1.TransactionConsumptionOverlay}

  alias EWallet.{
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionConsumerGate,
    Web.V1.Event
  }

  alias EWalletDB.TransactionConsumption

  def consume_for_user(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    attrs =
      attrs
      |> Map.delete("exchange_account_id")
      |> Map.delete("exchange_wallet_address")

    with {:ok, consumption} <-
           TransactionConsumptionConsumerGate.consume(conn.assigns.end_user, attrs) do
      consumption
      |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
      |> respond(conn, true)
    else
      error ->
        respond(error, conn, true)
    end
  end

  def consume_for_user(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve_for_user(conn, attrs), do: confirm(conn, conn.assigns.end_user, attrs, true)
  def reject_for_user(conn, attrs), do: confirm(conn, conn.assigns.end_user, attrs, false)

  defp confirm(conn, user, %{"id" => id} = attrs, approved) do
    case TransactionConsumptionConfirmerGate.confirm(id, approved, %{end_user: user}) do
      {:ok, consumption} ->
        consumption
        |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
        |> respond(conn, true)

      error ->
        respond(error, conn, true)
    end
  end

  defp confirm(conn, _entity, _attrs, _approved), do: handle_error(conn, :invalid_parameter)

  defp respond({:error, error}, conn, _dispatch?) when is_atom(error) do
    handle_error(conn, error)
  end

  defp respond({:error, consumption, code, description}, conn, true) do
    dispatch_confirm_event(consumption)
    handle_error(conn, code, description)
  end

  defp respond({:error, _consumption, code, description}, conn, false) do
    handle_error(conn, code, description)
  end

  defp respond({:ok, consumption}, conn, true) do
    dispatch_confirm_event(consumption)
    respond({:ok, consumption}, conn, false)
  end

  defp respond({:ok, consumption}, conn, false) do
    render(conn, :transaction_consumption, %{transaction_consumption: consumption})
  end

  defp dispatch_confirm_event(consumption) do
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end
end
