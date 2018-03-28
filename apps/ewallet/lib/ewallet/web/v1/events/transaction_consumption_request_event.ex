defmodule EWallet.Web.V1.TransactionConsumptionRequestEvent do
  @moduledoc """
  This module represents the transaction_consumption_request event and how to build it.
  """
  alias EWallet.Web.V1.{Event, TransactionConsumptionSerializer}
  alias EWalletDB.User

  @spec broadcast(TransactionConsumption.t) :: :ok
  def broadcast(consumption) do
    consumption
    |> topics()
    |> Enum.each(fn topic ->
      Event.broadcast(
        topic: topic,
        event: event(),
        payload: payload(consumption)
      )
    end)
  end

  defp event do
    "transaction_consumption_request"
  end

  defp topics(consumption) do
    topics = [
      "address:#{consumption.transaction_request.balance_address}",
      "transaction_request:#{consumption.transaction_request.id}"
    ]

    topics =
      case consumption.user_id do
        nil -> topics
        id ->
          user = User.get(id)
          topics ++ ["user:#{user.provider_user_id}"]
      end

    topics
    |> put_in_topic_if_present("account", consumption.transaction_request.account_id)
    |> put_in_topic_if_present("user", consumption.transaction_request.user_id)
  end

  defp put_in_topic_if_present(topics, _key, nil), do: topics
  defp put_in_topic_if_present(topics, field, value) do
    topics ++ ["#{field}:#{value}"]
  end

  defp payload(consumption) do
    consumption
    |> TransactionConsumptionSerializer.serialize()
  end
end
