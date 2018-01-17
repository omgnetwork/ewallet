defmodule EWalletAdmin.V1.AccountViewTest do
  use EWalletAdmin.ViewCase, :v1
  alias EWallet.Web.{Paginator, Date}
  alias EWalletAdmin.V1.AccountView

  describe "EWalletAdmin.V1.AccountView.render/2" do
    test "renders account.json with correct response structure" do
      account = insert(:account)
      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "account",
          id: account.id,
          name: account.name,
          description: account.description,
          master: account.master,
          created_at: Date.to_iso8601(account.inserted_at),
          updated_at: Date.to_iso8601(account.updated_at)
        }
      }

      assert AccountView.render("account.json", %{account: account}) == expected
    end

    test "renders accounts.json with correct response structure" do
      account1 = insert(:account)
      account2 = insert(:account)

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
              master: account1.master,
              created_at: Date.to_iso8601(account1.inserted_at),
              updated_at: Date.to_iso8601(account1.updated_at)
            },
            %{
              object: "account",
              id: account2.id,
              name: account2.name,
              description: account2.description,
              master: account2.master,
              created_at: Date.to_iso8601(account2.inserted_at),
              updated_at: Date.to_iso8601(account2.updated_at)
            }
          ],
          pagination: %{
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: false,
          },
        }
      }

      assert AccountView.render("accounts.json", %{accounts: paginator}) == expected
    end
  end
end
