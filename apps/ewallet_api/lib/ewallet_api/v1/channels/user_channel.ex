defmodule EWalletAPI.V1.UserChannel do
  @moduledoc """
  Represents the user channel.
  """
  use Phoenix.Channel

  def join("user:" <> _user_id, _params, socket) do
    {:ok, socket}
  end
end
