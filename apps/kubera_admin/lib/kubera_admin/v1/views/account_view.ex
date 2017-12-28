defmodule KuberaAdmin.V1.AccountView do
  use KuberaAdmin, :view
  alias KuberaAdmin.V1.{ResponseSerializer, AccountSerializer}

  def render("account.json", %{account: account}) do
    account
    |> AccountSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("accounts.json", %{accounts: accounts}) do
    accounts.data
    |> AccountSerializer.to_json()
    |> ResponseSerializer.to_json(success: true, pagination: accounts.pagination)
  end
end
