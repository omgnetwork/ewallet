defmodule AdminAPI.V1.AccountView do
  use AdminAPI, :view
  alias AdminAPI.V1.{ResponseSerializer, AccountSerializer}

  def render("account.json", %{account: account}) do
    account
    |> AccountSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
  def render("accounts.json", %{accounts: accounts}) do
    accounts
    |> AccountSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
