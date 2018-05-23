defmodule AdminAPI.V1.AccountMembershipView do
  use AdminAPI, :view
  alias AdminAPI.V1.MembershipSerializer
  alias EWallet.Web.V1.ResponseSerializer

  def render("memberships.json", %{memberships: memberships}) do
    memberships
    |> MembershipSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty.json", %{success: success}) do
    %{}
    |> ResponseSerializer.serialize(success: success)
  end
end
