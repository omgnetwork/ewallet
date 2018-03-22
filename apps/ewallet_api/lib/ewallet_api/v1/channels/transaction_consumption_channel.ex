defmodule EWalletAPI.V1.TransactionConsumptionChannel do
  @moduledoc """
  Represents the transaction consumption channel.
  """
  use Phoenix.Channel

  def join("transaction_consumption:" <> _request_id, _params, socket) do
    {:ok, socket}
  end
end
