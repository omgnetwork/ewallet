defmodule EWalletAPI.V1.ResetPasswordView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.ResponseSerializer

  def render("empty.json", %{success: success}) do
    %{}
    |> ResponseSerializer.serialize(success: success)
  end
end
