defmodule KuberaAdmin.V1.MintedTokenControllerTest do
  use KuberaAdmin.ConnCase, async: true

  describe "/minted_token.all" do
    test "returns a list of minted tokens and pagination data" do
      response = user_request("/minted_token.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer pagination["per_page"]
      assert is_integer pagination["current_page"]
      assert is_boolean pagination["is_last_page"]
      assert is_boolean pagination["is_first_page"]
    end

    test "returns a list of minted tokens according to search_term, sort_by and sort_direction" do
      insert(:minted_token, %{symbol: "ABC1"})
      insert(:minted_token, %{symbol: "ABC3"})
      insert(:minted_token, %{symbol: "ABC2"})
      insert(:minted_token, %{symbol: "XYZ1"})

      attrs = %{
        "search_term" => "aBc", # Search is case-insensitive
        "sort_by"     => "symbol",
        "sort_dir"    => "desc"
      }

      response = user_request("/minted_token.all", attrs)
      minted_tokens = response["data"]["data"]

      assert response["success"]
      assert Enum.count(minted_tokens) == 3
      assert Enum.at(minted_tokens, 0)["symbol"] == "ABC3"
      assert Enum.at(minted_tokens, 1)["symbol"] == "ABC2"
      assert Enum.at(minted_tokens, 2)["symbol"] == "ABC1"
    end
  end

  describe "/minted_token.get" do
    test "returns a minted token by the given ID" do
      minted_tokens = insert_list(3, :minted_token)
      target        = Enum.at(minted_tokens, 1) # Pick the 2nd inserted minted token
      response      = user_request("/minted_token.get", %{"id" => target.friendly_id})

      assert response["success"]
      assert response["data"]["object"] == "minted_token"
      assert response["data"]["id"] == target.friendly_id
    end

    test "returns 'minted_token:id_not_found' if the given ID was not found" do
      response  = user_request("/minted_token.get", %{"id" => "wrong_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "minted_token:id_not_found"
      assert response["data"]["description"] ==
        "There is no minted token corresponding to the provided id"
    end

    test "returns 'client:invalid_parameter' if id was not provided" do
      response  = user_request("/minted_token.get", %{"not_id" => "minted_token_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end
  end
end
