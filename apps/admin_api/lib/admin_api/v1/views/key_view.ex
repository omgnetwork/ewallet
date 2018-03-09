defmodule AdminAPI.V1.KeyView do
  use AdminAPI, :view
  alias AdminAPI.V1.{KeySerializer, ResponseSerializer}

  def render("key.json", %{key: key}) do
    key
    |> KeySerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
  def render("keys.json", %{keys: keys}) do
    keys
    |> KeySerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
  def render("empty_response.json", _attrs) do
    ResponseSerializer.serialize(%{}, success: true)
  end
end
