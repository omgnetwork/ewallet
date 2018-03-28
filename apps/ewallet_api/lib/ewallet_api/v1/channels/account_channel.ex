defmodule EWalletAPI.V1.AccountChannel do
  @moduledoc """
  Represents the account channel.
  """
  use Phoenix.Channel

  def join("account:" <> _account_id, _params, socket) do
    {:ok, socket}
  end
end
