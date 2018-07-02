defmodule EWallet.TokenFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.TokenFetcher

  describe "fetch/3 with token_id" do
    test "sets the token in both from_token and to_token" do
      token = insert(:token)

      {res, from, to} =
        TokenFetcher.fetch(
          %{
            "token_id" => token.id
          },
          %{},
          %{}
        )

      assert res == :ok
      assert from.from_token.uuid == token.uuid
      assert to.to_token.uuid == token.uuid
    end

    test "returns error if the token does not exist" do
      {res, code} =
        TokenFetcher.fetch(
          %{
            "token_id" => "fake"
          },
          %{},
          %{}
        )

      assert res == :error
      assert code == :token_not_found
    end
  end

  describe "fetch/3 with from_token_id and to_token_id" do
    test "sets the from_token and to_token when given valid IDs" do
      token = insert(:token)

      {res, from, to} =
        TokenFetcher.fetch(
          %{
            "from_token_id" => token.id,
            "to_token_id" => token.id
          },
          %{},
          %{}
        )

      assert res == :ok
      assert from.from_token.uuid == token.uuid
      assert to.to_token.uuid == token.uuid
    end

    test "sets the from_token and to_token when given valid  different IDs" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      {res, from, to} =
        TokenFetcher.fetch(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id
          },
          %{},
          %{}
        )

      assert res == :ok
      assert from.from_token.uuid == token_1.uuid
      assert to.to_token.uuid == token_2.uuid
    end

    test "returns error if the from_token does not exist" do
      token_2 = insert(:token)

      {res, code} =
        TokenFetcher.fetch(
          %{
            "from_token_id" => "fake",
            "to_token_id" => token_2.id
          },
          %{},
          %{}
        )

      assert res == :error
      assert code == :from_token_not_found
    end

    test "returns error if the to_token does not exist" do
      token_1 = insert(:token)

      {res, code} =
        TokenFetcher.fetch(
          %{
            "from_token_id" => token_1.id,
            "to_token_id" => "fake"
          },
          %{},
          %{}
        )

      assert res == :error
      assert code == :to_token_not_found
    end
  end

  describe "fetch/3 with invalid params" do
    test "returns error if the to_token does not exist" do
      {res, code, desc} = TokenFetcher.fetch(%{}, %{}, %{})

      assert res == :error
      assert code == :invalid_parameter
      assert desc == "'token_id' or a pair 'from_token_id'/'to_token_id' is required."
    end
  end
end
