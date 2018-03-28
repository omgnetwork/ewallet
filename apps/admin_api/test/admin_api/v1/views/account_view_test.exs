defmodule AdminAPI.V1.AccountViewTest do
  use AdminAPI.ViewCase, :v1
  alias EWallet.Web.{Paginator, Date}
  alias EWalletDB.Account
  alias AdminAPI.V1.AccountView

  describe "AdminAPI.V1.AccountView.render/2" do
    test "renders account.json with correct response structure" do
      account = insert(:account)
      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "account",
          id: account.id,
          socket_topic: "account:#{account.id}",
          parent_id: account.parent_id,
          name: account.name,
          description: account.description,
          master: Account.master?(account),
          avatar: %{
            original: nil,
            large: nil,
            small: nil,
            thumb: nil
          },
          metadata: %{},
          encrypted_metadata: %{},
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
              socket_topic: "account:#{account1.id}",
              parent_id: account1.parent_id,
              name: account1.name,
              description: account1.description,
              master: Account.master?(account1),
              avatar: %{
                original: nil,
                large: nil,
                small: nil,
                thumb: nil
              },
              metadata: %{},
              encrypted_metadata: %{},
              created_at: Date.to_iso8601(account1.inserted_at),
              updated_at: Date.to_iso8601(account1.updated_at)
            },
            %{
              object: "account",
              id: account2.id,
              socket_topic: "account:#{account2.id}",
              parent_id: account2.parent_id,
              name: account2.name,
              description: account2.description,
              master: Account.master?(account2),
              avatar: %{
                original: nil,
                large: nil,
                small: nil,
                thumb: nil
              },
              metadata: %{},
              encrypted_metadata: %{},
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
