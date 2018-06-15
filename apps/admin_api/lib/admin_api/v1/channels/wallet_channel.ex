# credo:disable-for-this-file
defmodule AdminAPI.V1.WalletChannel do
  @moduledoc """
  Represents the address channel.
  """
  use Phoenix.Channel
  alias EWalletDB.{User, Wallet}

  def join("address:" <> address, _params, %{assigns: %{auth: auth}} = socket) do
    address
    |> Wallet.get()
    |> join_as(auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(nil, _auth, _socket), do: {:error, :channel_not_found}

  defp join_as(_wallet, %{authenticated: :provider}, socket) do
    {:ok, socket}
  end

  defp join_as(wallet, %{authenticated: :client, user: user}, socket) do
    user
    |> User.addresses()
    |> Enum.member?(wallet.address)
    |> case do
      true -> {:ok, socket}
      false -> {:error, :forbidden_channel}
    end
  end
end
