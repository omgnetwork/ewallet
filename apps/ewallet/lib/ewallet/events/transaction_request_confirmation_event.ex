defmodule EWallet.TransactionRequestConfirmationEvent do
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
    "transaction_request_confirmation"
  end

  defp topics(consumption) do
    topics = [
      "address:#{consumption.transaction_request.balance_address}",
      "transaction_request:#{consumption.transaction_request.id}"
    ]

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
    |> EWallet.Web.V1.TransactionRequestConsumptionSerializer.serialize()
  end
end
