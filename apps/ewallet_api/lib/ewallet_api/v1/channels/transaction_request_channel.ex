defmodule EWalletAPI.V1.TransactionRequestChannel do
  use Phoenix.Channel

  def join("transaction_request:" <> request_id, params, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end
end
