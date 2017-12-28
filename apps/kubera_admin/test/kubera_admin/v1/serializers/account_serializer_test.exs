defmodule KuberaAdmin.V1.AccountSerializerTest do
  use KuberaAdmin.SerializerCase, :v1
  alias KuberaAdmin.V1.AccountSerializer

  describe "AccountSerializer.to_json/1" do
    test "serializes an account into V1 response format" do
      account = build(:account)

      expected = %{
        object: "account",
        id: account.id,
        name: account.name,
        description: account.description,
        master: account.master
      }

      assert AccountSerializer.to_json(account) == expected
    end

    test "serializes accounts into V1 response format" do
      account1 = build(:account)
      account2 = build(:account)
      accounts = [account1, account2]

      expected = %{
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
      }

      assert AccountSerializer.to_json(accounts) == expected
    end
  end
end
