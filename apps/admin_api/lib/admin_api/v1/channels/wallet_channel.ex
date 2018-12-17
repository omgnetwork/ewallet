# credo:disable-for-this-file
defmodule AdminAPI.V1.WalletChannel do
  @moduledoc """
  Represents the address channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.Wallet
  alias EWallet.WalletPolicy

  def join("address:" <> address, _params, %{assigns: %{auth: auth}} = socket) do
    with %Wallet{} = wallet <- Wallet.get(address),
         :ok <- Bodyguard.permit(WalletPolicy, :join, auth, wallet) do
      {:ok, socket}
    else
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
