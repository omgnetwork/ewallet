defmodule AdminAPI.V1.RoleView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{RoleSerializer, ResponseSerializer}

  def render("role.json", %{role: role}) do
    role
    |> RoleSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("roles.json", %{roles: roles}) do
    roles
    |> RoleSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
