defmodule KuberaAdmin.V1.AccountViewTest do
  use KuberaAdmin.ViewCase, :v1
  alias KuberaAdmin.V1.AccountView

  describe "KuberaAdmin.V1.AccountView.render/2" do
    test "renders account.json with correct response structure" do
      account = build(:account)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "account",
          id: account.id,
          name: account.name,
          description: account.description,
          master: account.master
        }
      }

      assert AccountView.render("account.json", %{account: account}) == expected
    end

    test "renders accounts.json with correct response structure" do
      account1 = build(:account)
      account2 = build(:account)
      accounts = [account1, account2]

      expected = %{
        version: @expected_version,
        success: true,
        data: [
          %{
            object: "account",
            id: account1.id,
            name: account1.name,
            description: account1.description,
            master: account1.master
          },
          %{
            object: "account",
            id: account2.id,
            name: account2.name,
            description: account2.description,
            master: account2.master
          }
        ]
      }

      assert AccountView.render("accounts.json", %{accounts: accounts}) == expected
    end
  end
end
