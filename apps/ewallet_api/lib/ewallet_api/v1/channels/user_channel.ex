defmodule EWalletAPI.V1.UserChannel do
  use Phoenix.Channel

  def join("user:" <> provider_user_id, params, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", body, socket) do
    broadcast! socket, "new_msg", %{}
    {:noreply, socket}
  end
end
