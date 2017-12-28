defmodule KuberaAdmin.V1.AccountViewTest do
  use KuberaAdmin.ViewCase, :v1
  alias Kubera.Web.Paginator
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

      paginator = %Paginator{
        data: [account1, account2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false,
        },
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
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
        },
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false,
        },
      }

      assert AccountView.render("accounts.json", %{accounts: paginator}) == expected
    end
  end
end
