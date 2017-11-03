defmodule KuberaAPI.V1.Plug.ClientAuthTest do
  use KuberaAPI.ConnCase, async: true
  import KuberaDB.Factory, only: [insert: 2]
  alias Ecto.Adapters.SQL.Sandbox
  alias KuberaAPI.V1.Plug.ClientAuth
  alias KuberaDB.Repo
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

  describe "V1.Plugs.ProviderAuth" do
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

    test "halts and returns error code if auth content is invalid" do
      conn =
        build_conn()
        |> put_auth_header("OMGServer", "invalidformat")
        |> ClientAuth.call([])
      {:ok, body} = conn |> Map.get(:resp_body) |> Parser.parse()

      assert conn.halted
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :user)
      assert body["data"]["code"] == "client:invalid_auth_scheme"
    end
  end

  defp invoke_conn(api_key, auth_token) do
    build_conn()
    |> put_auth_header("OMGClient", api_key, auth_token)
    |> ClientAuth.call([])
  end
end
