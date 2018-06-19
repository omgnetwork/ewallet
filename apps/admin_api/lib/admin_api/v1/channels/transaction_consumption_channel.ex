# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionConsumptionChannel do
  @moduledoc """
  Represents the transaction consumption channel.
  """
  use Phoenix.Channel
  alias EWalletDB.TransactionConsumption

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

  defp join_as(_consumption, %{authenticated: true}, socket) do
    {:ok, socket}
  end
end
