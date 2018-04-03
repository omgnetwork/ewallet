defmodule EWalletDB.AuthTokenTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.AuthToken

  @owner_app :some_app

  describe "AuthToken.generate/1" do
    test "generates an auth token string with length == 43" do
      user = insert(:user)
      {res, auth_token} = AuthToken.generate(user, @owner_app)

      assert res == :ok
      assert String.length(auth_token) == 43
    end

    test "returns error if user is invalid" do
      account = insert(:account)
      {res, reason} = AuthToken.generate(account, @owner_app)

      assert res == :error
      assert reason == :invalid_parameter
    end

    test "allows multiple auth tokens for each user" do
      user = insert(:user)

      {:ok, token1} = AuthToken.generate(user, @owner_app)
      {:ok, token2} = AuthToken.generate(user, @owner_app)

      token_count =
        user
        |> Ecto.assoc(:auth_tokens)
        |> Repo.aggregate(:count, :id)

      assert String.length(token1) > 0
      assert String.length(token2) > 0
      assert token_count == 2
    end
  end

  describe "AuthToken.authenticate/2" do
    test "returns an existing token if exists" do
      user = insert(:user)
      {:ok, auth_token} = AuthToken.generate(user, @owner_app)

      auth_user = AuthToken.authenticate(auth_token, @owner_app)
      assert auth_user.id == user.id
    end

    test "returns :token_expired if token exists but expired" do
      {:ok, token} = :auth_token
        |> insert(%{owner_app: Atom.to_string(@owner_app)})
        |> AuthToken.expire()

      assert AuthToken.authenticate(token.token, @owner_app) == :token_expired
    end

    test "returns false if token exists but for a different owner app" do
      {:ok, token} = :auth_token
        |> insert(%{owner_app: "wrong_app"})
        |> AuthToken.expire()

      assert AuthToken.authenticate(token.token, @owner_app) == false
    end

    test "returns false if token does not exists" do
      assert AuthToken.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if auth token is nil" do
      assert AuthToken.authenticate(nil, @owner_app) == false
    end
  end

  describe "AuthToken.authenticate/3" do
    test "returns an existing token if user_id and token match" do
      user = insert(:admin)
      {:ok, auth_token} = AuthToken.generate(user, @owner_app)

      auth_user = AuthToken.authenticate(user.external_id, auth_token, @owner_app)
      assert auth_user.id == user.id
    end

    test "returns an existing token if user_id and token match and user has multiple tokens" do
      user = insert(:admin)
      {:ok, token1} = AuthToken.generate(user, @owner_app)
      {:ok, token2} = AuthToken.generate(user, @owner_app)

      assert AuthToken.authenticate(user.external_id, token1, @owner_app)
      assert AuthToken.authenticate(user.external_id, token2, @owner_app)
    end

    test "returns :token_expired if token exists but expired" do
      token = insert(:auth_token, %{owner_app: Atom.to_string(@owner_app)})
      AuthToken.expire(token)

      assert AuthToken.authenticate(token.user.external_id, token.token, @owner_app) == :token_expired
    end

    test "returns false if auth token belongs to a different user" do
      user = insert(:admin)
      {:ok, auth_token} = AuthToken.generate(user, @owner_app)

      another_user = insert(:admin)
      assert AuthToken.authenticate(another_user.external_id, auth_token, @owner_app) == false
    end

    test "returns false if token exists but for a different owner app" do
      user = insert(:admin)
      {:ok, auth_token} = AuthToken.generate(user, :different_app)

      assert AuthToken.authenticate(user.external_id, auth_token, @owner_app) == false
    end

    test "returns false if token does not exists" do
      user = insert(:admin)
      {:ok, _} = AuthToken.generate(user, @owner_app)

      assert AuthToken.authenticate(user.external_id, "unmatched", @owner_app) == false
    end

    test "returns false if auth token is nil" do
      user = insert(:admin)
      {:ok, _} = AuthToken.generate(user, @owner_app)

      assert AuthToken.authenticate(user.external_id, nil, @owner_app) == false
    end
  end

  describe "AuthToken.expire/1" do
    test "expires AuthToken sucessfully given an AuthToken" do
      token = insert(:auth_token, %{owner_app: Atom.to_string(@owner_app)})
      token_string = token.token

      assert AuthToken.authenticate(token_string, @owner_app) # Ensure token is usable.
      AuthToken.expire(token)
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end

    test "expires AuthToken successfully given the token string" do
      token = insert(:auth_token, %{owner_app: Atom.to_string(@owner_app)})
      token_string = token.token

      assert AuthToken.authenticate(token_string, @owner_app) # Ensure token is usable.
      AuthToken.expire(token_string, @owner_app)
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end
  end
end
