defmodule AdminAPI.V1.KeyView do
  use AdminAPI, :view
  alias AdminAPI.V1.{KeySerializer, ResponseSerializer}

  def render("key.json", %{key: key}) do
    key
    |> KeySerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("keys.json", %{keys: keys}) do
    keys
    |> KeySerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("empty_response.json", _attrs) do
    ResponseSerializer.to_json(%{}, success: true)
  end
end
