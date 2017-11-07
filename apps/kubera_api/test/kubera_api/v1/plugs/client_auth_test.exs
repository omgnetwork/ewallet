defmodule KuberaAPI.V1.Plug.ClientAuthTest do
  use KuberaAPI.ConnCase, async: true
  import KuberaDB.Factory, only: [insert: 2]
  alias Ecto.Adapters.SQL.Sandbox
  alias KuberaAPI.V1.Plug.ClientAuth
  alias KuberaDB.{Repo, AuthToken}
  alias Poison.Parser

  @api_key "test_api_key"
  @auth_token "test_auth_token"
  @username "test_username"

  # Setup sandbox and provider's access/secret keys
  setup do
    :ok = Sandbox.checkout(Repo)

    user = insert(:user, %{username: @username})
    insert(:api_key, %{key: @api_key})
    insert(:auth_token, %{user: user, token: @auth_token})

    :ok
  end

  describe "call/2" do
    test "assigns user if api key and auth token are correct" do
      conn = invoke_conn(@api_key, @auth_token)

      refute conn.halted
      assert conn.assigns[:authenticated] == :client
      assert conn.assigns.user.username == @username
    end

    test "halts and returns error code if api_key is missing" do
      conn = invoke_conn("", @auth_token)
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "client:invalid_api_key"
    end

    test "halts and returns error code if api_key is incorrect" do
      conn = invoke_conn("wrong_api_key", @auth_token)
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "client:invalid_api_key"
    end

    test "halts and returns error code if auth_token is missing" do
      conn = invoke_conn(@api_key, "")
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "user:access_token_not_found"
    end

    test "halts and returns error code if auth_token is incorrect" do
      conn = invoke_conn(@api_key, "wrong_auth_token")
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "user:access_token_not_found"
    end

    test "halts and returns error code if auth_token exists but expired" do
      AuthToken.expire(@auth_token)

      conn = invoke_conn(@api_key, @auth_token)
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "user:access_token_expired"
    end

    test "halts and returns error code if auth type is invalid" do
      conn =
        build_conn()
        |> put_auth_header("InvalidType", "access", "secret")
        |> ClientAuth.call([])
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "client:invalid_auth_scheme"
    end
  end

  describe "call/2 with invalid auth scheme" do
    test "halts with :invalid_auth_scheme if credentials format is invalid" do
      conn =
        build_conn()
        |> put_auth_header("OMGClient", "not_colon_separated_base64")
        |> ClientAuth.call([])
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "client:invalid_auth_scheme"
    end

    test "halts with :invalid_auth_scheme if auth header is not provided" do
      conn = build_conn() |> ClientAuth.call([])
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      assert conn.status == 200
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :account)
      assert body["data"]["code"] == "client:invalid_auth_scheme"
    end

    test "halts with :invalid_auth_scheme if auth scheme is not supported" do
      conn =
        build_conn()
        |> put_auth_header("InvalidScheme", @api_key, @auth_token)
        |> ClientAuth.call([])

      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      assert conn.status == 200
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :account)
      assert body["data"]["code"] == "client:invalid_auth_scheme"
    end
  end

  describe "expire_token/1" do
    test "expires auth token from the given connection successfully" do
      assert AuthToken.authenticate(@auth_token)

      conn =
        @api_key
        |> invoke_conn(@auth_token)
        |> ClientAuth.expire_token()

      assert AuthToken.authenticate(@auth_token) == :token_expired
      refute conn.assigns[:authenticated]
      refute conn.assigns[:user]
    end
  end

  defp invoke_conn(api_key, auth_token) do
    build_conn()
    |> put_auth_header("OMGClient", api_key, auth_token)
    |> ClientAuth.call([])
  end
end
