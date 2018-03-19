defmodule EWallet.TransactionRequestConsumptionChangeEvent do
  def broadcast(consumption) do
    consumption
    |> topics()
    |> Enum.each(fn topic ->
      EWallet.Event.broadcast(
        topic: topic,
        event: event(consumption),
        payload: payload(consumption)
      )
    end)
  end

  defp event(consumption) do
    "transaction_request_consumption_change"
  end

  defp topics(consumption) do
    topics = [
      "address:#{consumption.balance_address}",
      "transaction_request:#{consumption.transaction_request.id}",
      "transaction_request_consumption:#{consumption.id}"
    ]

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
    |> EWallet.Web.V1.TransactionRequestConsumptionSerializer.serialize()
  end
end
