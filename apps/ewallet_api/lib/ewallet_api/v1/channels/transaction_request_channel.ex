defmodule EWalletAPI.V1.TransactionRequestChannel do
  @moduledoc """
  Represents the transaction request channel.
  """
  use Phoenix.Channel

  def join("transaction_request:" <> _request_id, _params, socket) do
    {:ok, socket}
  end
end
