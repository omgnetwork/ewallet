defmodule EWalletAPI.V1.TransactionRequestChannel do
  use Phoenix.Channel

  def join("transaction_request:" <> _request_id, _params, socket) do
    {:ok, socket}
  end

  def handle_in("transaction_request_confirmation", body, socket) do
    broadcast! socket, "transaction_request_confirmation", body
    {:noreply, socket}
  end
end
