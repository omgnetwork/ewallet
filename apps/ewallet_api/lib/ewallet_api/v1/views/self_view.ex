defmodule EWalletAPI.V1.SelfView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{ListSerializer, ResponseSerializer, UserSerializer, WalletSerializer}
  alias EWalletAPI.V1.UserSettingsSerializer

  def render("user.json", %{user: user}) do
    user
    |> UserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("settings.json", settings) do
    settings
    |> UserSettingsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("wallets.json", %{wallets: wallets}) do
    wallets
    |> Enum.map(&WalletSerializer.serialize/1)
    |> ListSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
