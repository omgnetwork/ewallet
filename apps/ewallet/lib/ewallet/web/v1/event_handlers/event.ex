defmodule EWallet.Web.V1.Event do
  @moduledoc """
  This module translates a symbol defining a supported event into the actual event and broadcasts it.
  """
  alias EWallet.Web.V1.TransactionConsumptionEventHandler
  alias EWalletDB.{User, Account}

  @spec dispatch(Atom.t, Map.t) :: :ok
  def dispatch(event, attrs) do
    TransactionConsumptionEventHandler.broadcast(event, attrs)
  end

  @spec broadcast(Keyword.t) :: :ok
  def broadcast(
    event: event,
    topics: topics,
    payload: payload
  ) do
    Enum.each(topics, fn topic ->
      Enum.each(endpoints(), fn endpoint ->
        endpoint.broadcast(
          topic,
          event,
          payload
        )
      end)
    end)
  end

  def address_topic(topics, address), do: topics ++ ["address:#{address}"]
  def transaction_request_topic(topics, id), do: topics ++ ["transaction_request:#{id}"]
  def transaction_consumption_topic(topics, id), do: topics ++ ["transaction_consumption:#{id}"]
  def user_topic(topics, user_id) do
    case user_id do
      nil -> topics
      user_id ->
        user = User.get(user_id)
        topics ++ ["user:#{user.provider_user_id}", "user:#{user.id}"]
    end
  end
  def account_topic(topics, account_id) do
    case account_id do
      nil -> topics
      id ->
        account = Account.get(id)
        topics ++ ["account:#{account.id}"]
    end
  end

  defp endpoints do
    Application.get_env(:ewallet, :websocket_endpoints)
  end
end
