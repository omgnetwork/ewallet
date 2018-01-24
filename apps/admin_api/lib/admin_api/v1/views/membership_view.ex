defmodule AdminAPI.V1.MembershipView do
  use AdminAPI, :view
  alias AdminAPI.V1.{MembershipSerializer, ResponseSerializer}

  def render("memberships.json", %{memberships: memberships}) do
    memberships
    |> MembershipSerializer.to_user_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
