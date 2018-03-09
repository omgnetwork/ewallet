defmodule AdminAPI.V1.ResetPasswordView do
  use AdminAPI, :view
  alias AdminAPI.V1.ResponseSerializer

  def render("empty.json", %{success: success}) do
    %{}
    |> ResponseSerializer.serialize(success: success)
  end
end
