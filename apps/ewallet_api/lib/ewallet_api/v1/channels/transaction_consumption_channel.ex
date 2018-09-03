# credo:disable-for-this-file
defmodule EWalletAPI.V1.TransactionConsumptionChannel do
  @moduledoc """
  Represents the transaction consumption channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.{TransactionConsumption, User}

  def join(
        "transaction_consumption:" <> consumption_id,
        _params,
        %{
          assigns: %{auth: auth}
        } = socket
      ) do
    consumption_id
    |> TransactionConsumption.get()
    |> join_as(auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(nil, _auth, _socket), do: {:error, :channel_not_found}

  defp join_as(consumption, %{authenticated: true, user: user}, socket) do
    user
    |> User.addresses()
    |> Enum.member?(consumption.wallet_address)
    |> case do
      true -> {:ok, socket}
      false -> {:error, :forbidden_channel}
    end
  end
end
