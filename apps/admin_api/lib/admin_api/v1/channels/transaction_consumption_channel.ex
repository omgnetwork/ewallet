# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionConsumptionChannel do
  @moduledoc """
  Represents the transaction consumption channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.TransactionConsumption
  alias EWallet.TransactionConsumptionPolicy

  def join(
        "transaction_consumption:" <> consumption_id,
        _params,
        %{
          assigns: %{auth: auth}
        } = socket
      ) do
    with %TransactionConsumption{} = consumption <-
           TransactionConsumption.get(consumption_id, preload: [:account, :wallet]),
         :ok <- Bodyguard.permit(TransactionConsumptionPolicy, :join, auth, consumption) do
      {:ok, socket}
    else
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
