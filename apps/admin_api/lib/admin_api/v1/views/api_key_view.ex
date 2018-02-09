defmodule AdminAPI.V1.APIKeyView do
  use AdminAPI, :view
  alias AdminAPI.V1.{APIKeySerializer, ResponseSerializer}

  def render("api_keys.json", %{api_keys: api_keys}) do
    api_keys
    |> APIKeySerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
