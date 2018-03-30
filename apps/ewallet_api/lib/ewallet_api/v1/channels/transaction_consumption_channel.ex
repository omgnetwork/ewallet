defmodule EWalletAPI.V1.TransactionConsumptionChannel do
  @moduledoc """
  Represents the transaction consumption channel.
  """
  use Phoenix.Channel
  alias EWalletDB.{User, TransactionConsumption}

  def join("transaction_consumption:" <> consumption_id, _params, %{
    assigns: %{auth: auth}
  } = socket) do
    join_as(auth, socket, consumption_id)
  end
  def join(_, _, _), do: {:error, %{code: :invalid_parameter}}

  defp join_as(%{authenticated: :provider}, socket, _) do
    {:ok, socket}
  end

  defp join_as(%{authenticated: :client, user: user}, socket, consumption_id) do
    consumption_id
    |> TransactionConsumption.get()
    |> respond(socket, user)
  end

  defp respond(nil, socket, _), do: {:error, %{code: :channel_not_found}}
  defp respond(consumption, socket, user) do
    user
    |> User.addresses()
    |> Enum.member?(consumption.balance_address)
    |> case do
      true  -> {:ok, socket}
      false -> {:error, %{code: :forbidden_channel}}
    end
  end
end
