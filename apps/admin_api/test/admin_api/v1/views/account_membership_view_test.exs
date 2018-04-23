defmodule AdminAPI.V1.AccountMembershipViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWalletDB.Repo
  alias AdminAPI.V1.{MembershipSerializer, AccountMembershipView}

  describe "AccountMembershipView.render/2" do
    test "renders memberships.json with users response" do
      membership1 = :membership |> insert() |> Repo.preload([:user, :role])
      membership2 = :membership |> insert() |> Repo.preload([:user, :role])
      memberships = [membership1, membership2]

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
          data: [
            MembershipSerializer.serialize(membership1),
            MembershipSerializer.serialize(membership2)
          ]
        }
      }

      assert AccountMembershipView.render("memberships.json", %{memberships: memberships}) ==
               expected
    end

    test "renders empty.json correctly" do
      assert AccountMembershipView.render("empty.json", %{success: true}) ==
               %{
                 version: @expected_version,
                 success: true,
                 data: %{}
               }
    end
  end
end
