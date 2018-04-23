defmodule AdminAPI.V1.APIKeyView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{APIKeySerializer, ResponseSerializer}

  def render("api_key.json", %{api_key: api_key}) do
    api_key
    |> APIKeySerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("api_keys.json", %{api_keys: api_keys}) do
    api_keys
    |> APIKeySerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty_response.json", _attrs) do
    ResponseSerializer.serialize(%{}, success: true)
  end
end
