defmodule EWallet.Web.V1.Event do
  @moduledoc """
  This module translates a symbol defining a supported event into the actual event and broadcasts it.
  """
  require Logger
  alias EWallet.Web.V1.TransactionConsumptionEventHandler
  alias EWalletDB.{Account, User}

  @spec dispatch(atom(), map()) :: :ok
  def dispatch(event, attrs) do
    TransactionConsumptionEventHandler.broadcast(event, attrs)
  end

  @spec broadcast(keyword()) :: :ok
  def broadcast(
        event: event,
        topics: topics,
        payload: payload
      ) do
    _ = log(event, topics, payload)

    Enum.each(topics, fn topic ->
      Enum.each(endpoints(), fn endpoint ->
        broadcast_if_compiled(endpoint, topic, event, payload)
      end)
    end)
  end

  # We use 'Code.ensure_compiled?' to ensure the endpoints are loaded.
  # When running tests from inside the Admin API/eWallet API/eWallet sub apps,
  # those endpoint modules are not available and therefore should not be added to
  # the list of endpoints that needs to be notified. If they are and the
  # Event emitter tries to call them, it will result in a 500 error.
  defp broadcast_if_compiled(endpoint, topic, event, payload) do
    if Code.ensure_compiled?(endpoint) do
      endpoint.broadcast(
        topic,
        event,
        payload
      )
    end
  end

  def log(event, topics, payload) do
    _ = Logger.info("")
    _ = Logger.info("WEBSOCKET EVENT: Dispatching event '#{event}' to:")
    _ = Logger.info("-- Endpoints:")

    Enum.each(endpoints(), fn endpoint ->
      Logger.info("---- #{endpoint}")
    end)

    _ = Logger.info("-- Channels:")

    Enum.each(topics, fn topic ->
      Logger.info("---- #{topic}")
    end)

    _ =
      case payload[:error] do
        nil ->
          Logger.info("With no errors.")

        error ->
          _ = Logger.info("With error:")
          error |> inspect() |> Logger.info()
      end

    _ = Logger.info("Ending event dispatch...")
    Logger.info("")
  end

  def address_topic(topics, address), do: topics ++ ["address:#{address}"]
  def transaction_request_topic(topics, id), do: topics ++ ["transaction_request:#{id}"]
  def transaction_consumption_topic(topics, id), do: topics ++ ["transaction_consumption:#{id}"]

  def user_topic(topics, user_id) do
    case user_id do
      nil ->
        topics

      user_id ->
        user = User.get(user_id)
        topics ++ ["user:#{user.provider_user_id}", "user:#{user.id}"]
    end
  end

  def account_topic(topics, account_id) do
    case account_id do
      nil ->
        topics

      id ->
        account = Account.get(id)
        topics ++ ["account:#{account.id}"]
    end
  end

  defp endpoints do
    Application.get_env(:ewallet, :websocket_endpoints)
  end
end
