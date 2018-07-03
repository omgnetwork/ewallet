# credo:disable-for-this-file
defmodule AdminAPI.V1.WalletChannel do
  @moduledoc """
  Represents the address channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.Wallet

  def join("address:" <> address, _params, %{assigns: %{auth: auth}} = socket) do
    address
    |> Wallet.get()
    |> join_as(auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(nil, _auth, _socket), do: {:error, :channel_not_found}

  defp join_as(_wallet, %{authenticated: true}, socket) do
    {:ok, socket}
  end
end
