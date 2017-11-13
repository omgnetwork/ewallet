defmodule KuberaAPI.V1.SelfView do
  use KuberaAPI, :view
  use KuberaAPI.V1
  alias KuberaAPI.V1.JSON.{UserSerializer, UserSettingsSerializer,
    ResponseSerializer, AddressSerializer, ListSerializer}

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

  def render("balances.json", %{addresses: addresses}) do
    addresses
    |> Enum.map(&AddressSerializer.serialize/1)
    |> ListSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
