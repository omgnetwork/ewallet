defmodule AdminAPI.V1.AccountMembershipViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.Date
  alias AdminAPI.V1.AccountMembershipView

  describe "AccountMembershipView.render/2" do
    test "renders memberships.json with users response" do
      membership1 = insert(:membership)
      membership2 = insert(:membership)
      memberships = [membership1, membership2]

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
          data: [
            %{
              object: "user",
              id: membership1.user.id,
              username: membership1.user.username,
              provider_user_id: membership1.user.provider_user_id,
              email: membership1.user.email,
              avatar: %{original: nil, large: nil, small: nil, thumb: nil},
              account_role: membership1.role.name,
              status: :active,
              metadata: %{
                "first_name" => membership1.user.metadata["first_name"],
                "last_name" => membership1.user.metadata["last_name"]
              },
              created_at: Date.to_iso8601(membership1.user.inserted_at),
              updated_at: Date.to_iso8601(membership1.user.updated_at)
            },
            %{
              object: "user",
              id: membership2.user.id,
              username: membership2.user.username,
              provider_user_id: membership2.user.provider_user_id,
              email: membership2.user.email,
              avatar: %{original: nil, large: nil, small: nil, thumb: nil},
              account_role: membership2.role.name,
              status: :active,
              metadata: %{
                "first_name" => membership2.user.metadata["first_name"],
                "last_name" => membership2.user.metadata["last_name"]
              },
              created_at: Date.to_iso8601(membership2.user.inserted_at),
              updated_at: Date.to_iso8601(membership2.user.updated_at)
            }
          ]
        }
      }

      assert AccountMembershipView.render("memberships.json", %{memberships: memberships}) == expected
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
