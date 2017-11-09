defmodule KuberaDB.AuthTokenTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{Repo, AuthToken, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "has a valid factory" do
    changeset = AuthToken.changeset(%AuthToken{}, params_for(:auth_token))
    assert changeset.valid?
  end

  describe "changeset/2" do
  test "validates token can't be blank" do
      changeset =
        %AuthToken{}
        |> AuthToken.changeset(params_for(:auth_token, %{token: nil}))

      refute changeset.valid?
      assert changeset.errors ==
        [token: {"can't be blank", [validation: :required]}]
    end

    test "validates user can't be blank" do
      changeset =
        %AuthToken{}
        |> AuthToken.changeset(params_for(:auth_token, %{user: nil}))

      refute changeset.valid?
      assert changeset.errors ==
        [user_id: {"can't be blank", [validation: :required]}]
    end
  end

  describe "generate/1" do
    test "generates an auth token string with length == 43" do
      {:ok, user} = :user |> params_for() |> User.insert()
      auth_token = AuthToken.generate(user)

      assert String.length(auth_token) == 43
    end

    test "allows multiple auth tokens for each user" do
      {:ok, user} = :user |> params_for() |> User.insert()

      token1 = AuthToken.generate(user)
      token2 = AuthToken.generate(user)
      token_count =
        user
        |> Ecto.assoc(:auth_tokens)
        |> Repo.aggregate(:count, :id)

      assert String.length(token1) > 0
      assert String.length(token2) > 0
      assert token_count == 2
    end
  end

  describe "authenticate/2" do
    test "returns an existing token if exists" do
      {:ok, user} = :user |> params_for() |> User.insert()
      auth_token_string = AuthToken.generate(user)

      auth_user = AuthToken.authenticate(auth_token_string)
      assert auth_user.id == user.id
    end

    test "returns :token_expired if token exists but expired" do
      {:ok, token} = :auth_token
        |> insert()
        |> AuthToken.expire()

      assert AuthToken.authenticate(token.token) == :token_expired
    end

    test "returns false if token does not exists" do
      assert AuthToken.authenticate("unmatched") == false
    end

    test "returns false if auth token is nil" do
      assert AuthToken.authenticate(nil) == false
    end
  end

  describe "expire/1" do
    test "expires AuthToken sucessfully given an AuthToken" do
      token = insert(:auth_token)
      token_string = token.token

      assert AuthToken.authenticate(token_string) # Ensure token is usable.
      AuthToken.expire(token)
      assert AuthToken.authenticate(token_string) == :token_expired
    end

    test "expires AuthToken successfully given the token string" do
      token = insert(:auth_token)
      token_string = token.token

      assert AuthToken.authenticate(token_string) # Ensure token is usable.
      AuthToken.expire(token_string)
      assert AuthToken.authenticate(token_string) == :token_expired
    end
  end
end
