defmodule EWallet.TransactionRequestConfirmationEvent do
  def broadcast(consumption) do
    consumption
    |> channels()
    |> Enum.each(fn channel ->
      EWallet.Event.broadcast(
        channel: channel,
        topic: topic(consumption),
        payload: payload(consumption)
      )
    end)
  end

  defp topic(consumption) do
    "transaction_request_confirmation"
  end

  defp channels(consumption) do
    channels = [
      "address:#{consumption.transaction_request.balance_address}",
      "transaction_request:#{consumption.transaction_request.id}"
    ]

    channels
    |> put_in_channel_if_present("account", consumption.transaction_request.account_id)
    |> put_in_channel_if_present("user", consumption.transaction_request.user_id)
  end

  defp put_in_channel_if_present(channels, _key, nil), do: channels
  defp put_in_channel_if_present(channels, field, value) do
    channels ++ ["#{field}:#{value}"]
  end

  defp payload(consumption) do
    consumption
    |> EWallet.Web.V1.TransactionRequestConsumptionSerializer.serialize()
    |> EWallet.Web.V1.ResponseSerializer.serialize(success: true)
  end
end
