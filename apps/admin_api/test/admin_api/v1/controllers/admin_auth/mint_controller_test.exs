defmodule AdminAPI.V1.AdminAuth.MintControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.MintGate
  alias EWallet.Web.Date
  alias EWallet.Web.V1.{AccountSerializer, TokenSerializer, TransactionSerializer}
  alias EWalletDB.{Repo, Mint}

  describe "/token.get_mints" do
    test "returns a list of mints and pagination data" do
      token = insert(:token)

      {:ok, inserted_mint, _} =
        MintGate.insert(%{
          "idempotency_token" => "123",
          "token_id" => token.id,
          "amount" => 100_000,
          "description" => "desc."
        })

      inserted_mint = Repo.preload(inserted_mint, [:account, :token, :transaction])

      {:ok, _, _} =
        MintGate.insert(%{
          "idempotency_token" => "123",
          "token_id" => token.id,
          "amount" => 100_000,
          "description" => "desc."
        })

      response =
        admin_user_request("/token.get_mints", %{
          "id" => token.id,
          "sort_by" => "asc",
          "sort" => "created_at"
        })

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])
      assert length(response["data"]["data"]) == 2

      Enum.member?(response["data"]["data"], %{
        "account" => inserted_mint.account |> AccountSerializer.serialize() |> stringify_keys(),
        "account_id" => inserted_mint.account.id,
        "amount" => 100_000,
        "confirmed" => true,
        "description" => "desc.",
        "id" => inserted_mint.id,
        "object" => "mint",
        "token" => inserted_mint.token |> TokenSerializer.serialize() |> stringify_keys(),
        "token_id" => inserted_mint.token.id,
        "transaction" =>
          inserted_mint.transaction |> TransactionSerializer.serialize() |> stringify_keys(),
        "transaction_id" => inserted_mint.transaction.id,
        "created_at" => Date.to_iso8601(inserted_mint.inserted_at),
        "updated_at" => Date.to_iso8601(inserted_mint.updated_at)
      })

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of mints according to search_term, sort_by and sort_direction" do
      token = insert(:token)

      insert(:mint, %{token_uuid: token.uuid, description: "XYZ1"})
      insert(:mint, %{token_uuid: token.uuid, description: "XYZ3"})
      insert(:mint, %{token_uuid: token.uuid, description: "XYZ2"})

      attrs = %{
        # Search is case-insensitive
        "id" => token.id,
        "search_term" => "xYz",
        "sort_by" => "description",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/token.get_mints", attrs)

      mints = response["data"]["data"]

      assert response["success"]
      assert Enum.count(mints) == 3
      assert Enum.at(mints, 0)["description"] == "XYZ3"
      assert Enum.at(mints, 1)["description"] == "XYZ2"
      assert Enum.at(mints, 2)["description"] == "XYZ1"
    end
  end

  describe "/token.mint" do
    test "mints an existing token" do
      token = insert(:token)

      response =
        admin_user_request("/token.mint", %{
          id: token.id,
          amount: 1_000_000 * token.subunit_to_unit
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "mint"
      assert Mint.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.amount == 1_000_000 * token.subunit_to_unit
      assert mint.token_uuid == token.uuid
    end

    test "fails to mint a non existing token" do
      response =
        admin_user_request("/token.mint", %{
          id: "123",
          amount: 1_000_000
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "token:id_not_found"
    end

    test "fails to mint with mint amount sent as string" do
      token = insert(:token)

      response =
        admin_user_request("/token.mint", %{
          id: token.id,
          amount: "abc"
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "invalid_parameter"
    end

    test "fails to mint with mint amount == 0" do
      token = insert(:token)

      response =
        admin_user_request("/token.mint", %{
          id: token.id,
          amount: 0
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided `amount` must be greater than %{number}."

      assert response["data"]["messages"] == %{"amount" => ["number"]}
    end

    test "fails to mint with mint amount < 0" do
      token = insert(:token)

      response =
        admin_user_request("/token.mint", %{
          id: token.id,
          amount: -1
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided `amount` must be greater than %{number}."

      assert response["data"]["messages"] == %{"amount" => ["number"]}
    end
  end
end
