defmodule AdminAPI.V1.TransactionConsumptionController do
  use AdminAPI, :controller
  alias EWallet.Web.Embedder
  @behaviour EWallet.Web.Embedder
  import AdminAPI.V1.ErrorHandler

  alias EWallet.{
    Web.V1.Event,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionConfirmerGate
  }

  alias EWalletDB.{Account, TransactionConsumption}

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  def embeddable, do: [:account, :token, :transaction, :transaction_request, :user]

  # The fields returned by `embeddable/0` are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  def always_embed, do: [:token]

  def consume(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    attrs
    |> TransactionConsumptionConsumerGate.consume()
    |> respond(conn)
  end

  def consume(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve(conn, attrs), do: confirm(conn, get_actor(conn.assigns), attrs, true)
  def reject(conn, attrs), do: confirm(conn, get_actor(conn.assigns), attrs, false)

  defp get_actor(%{admin_user: _admin_user}) do
    # To do -> change this to actually check if the user has admin rights over the
    # owner of the consumption
    Account.get_master_account()
  end

  defp get_actor(%{key: key}) do
    key.account
  end

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
      transaction_consumption: Embedder.embed(__MODULE__, consumption, conn.body_params["embed"])
    })
  end

  defp dispatch_confirm_event(consumption) do
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end
end
