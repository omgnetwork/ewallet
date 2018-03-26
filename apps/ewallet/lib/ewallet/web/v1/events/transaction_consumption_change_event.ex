defmodule EWallet.Web.V1.TransactionConsumptionChangeEvent do
  @moduledoc """
  This module represents the transaction_consumption_change event and how to build it.
  """
  alias  EWallet.Web.V1.{Event, TransactionConsumptionSerializer}
  alias EWalletDB.{User, TransactionConsumption}

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
    "transaction_consumption_change"
  end

  defp topics(consumption) do
    topics = [
      "address:#{consumption.balance_address}",
      "transaction_request:#{consumption.transaction_request.id}",
      "transaction_consumption:#{consumption.id}"
    ]

    topics =
      case consumption.user_id do
        nil -> topics
        id ->
          user = User.get(id)
          topics ++ ["user:#{user.provider_user_id}"]
      end

    topics
    |> put_in_topic_if_present("account", consumption.account_id)
    |> put_in_topic_if_present("user", consumption.user_id)
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
