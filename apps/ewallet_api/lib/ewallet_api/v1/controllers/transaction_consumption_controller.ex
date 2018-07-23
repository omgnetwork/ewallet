defmodule EWalletAPI.V1.TransactionConsumptionController do
  use EWalletAPI, :controller
  alias EWallet.Web.Embedder
  @behaviour EWallet.Web.Embedder
  import EWalletAPI.V1.ErrorHandler

  alias EWallet.{
    Web.V1.Event,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionConfirmerGate
  }

  alias EWalletDB.TransactionConsumption

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  def embeddable, do: [:account, :token, :transaction, :transaction_request, :user]

  # The fields returned by `embeddable/0` are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  def always_embed, do: [:token]

  def consume_for_user(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    conn.assigns.user
    |> TransactionConsumptionConsumerGate.consume(attrs)
    |> respond(conn, true)
  end

  def consume_for_user(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve_for_user(conn, attrs), do: confirm(conn, conn.assigns.user, attrs, true)
  def reject_for_user(conn, attrs), do: confirm(conn, conn.assigns.user, attrs, false)

  defp confirm(conn, user, %{"id" => id}, approved) do
    case TransactionConsumptionConfirmerGate.confirm(id, approved, %{end_user: user}) do
      {:ok, consumption} ->
        respond({:ok, consumption}, conn, true)

      error ->
        respond(error, conn, true)
    end
  end

  defp confirm(conn, _entity, _attrs, _approved), do: handle_error(conn, :invalid_parameter)

  defp respond({:error, %TransactionConsumption{} = consumption, code}, conn, true) do
    dispatch_confirm_event(consumption)
    handle_error(conn, code)
  end

  defp respond({:error, %TransactionConsumption{} = _consumption, code}, conn, false) do
    handle_error(conn, code)
  end

  defp respond({:error, error}, conn, _dispatch?) when is_atom(error) do
    handle_error(conn, error)
  end

  defp respond({:error, changeset}, conn, _dispatch?) do
    handle_error(conn, :invalid_parameter, changeset)
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
    render(conn, :transaction_consumption, %{
      transaction_consumption: Embedder.embed(__MODULE__, consumption, conn.body_params["embed"])
    })
  end

  defp dispatch_confirm_event(consumption) do
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end
end
