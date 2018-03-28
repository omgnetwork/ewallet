defmodule EWalletAPI.V1.AddressChannel do
  @moduledoc """
  Represents the address channel.
  """
  use Phoenix.Channel

  def join("address:" <> _address, _params, socket) do
    {:ok, socket}
  end
end
