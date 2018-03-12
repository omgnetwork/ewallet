defmodule EWalletAPI.V1.UserChannel do
  use Phoenix.Channel

  def join("user:" <> request_id, params, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body}
    {:noreply, socket}
  end
end
