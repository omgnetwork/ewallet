defmodule EWalletAPI.V1.UserChannel do
  @moduledoc """
  Represents the user channel.
  """
  use Phoenix.Channel

  def join("user:" <> provider_user_id, params, socket) do
    {:ok, socket}
  end
end
