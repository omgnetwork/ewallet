defmodule KuberaAPI.V1.Plug.ProviderAuthTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  import KuberaDB.Factory, only: [insert: 2]
  alias Ecto.Adapters.SQL.Sandbox
  alias KuberaAPI.V1.Plug.ProviderAuth
  alias KuberaDB.Repo

  @access_key "test_access_key"
  @secret_key "test_secret_key"

  # Setup sandbox and provider's access/secret keys
  setup do
    :ok = Sandbox.checkout(Repo)
    insert(:key, %{access_key: @access_key, secret_key: @secret_key})
    :ok
  end

  describe "V1.Plugs.ProviderAuth with OMGServer auth type" do
    test "assigns authenticated and account if access/secret key are correct" do
      conn =
        build_conn()
        |> put_req_header("authorization", "OMGServer " <> Base.encode64(@access_key <> ":" <> @secret_key))
        |> ProviderAuth.call([])

      refute conn.halted
      assert conn.assigns[:authenticated]
      assert Map.has_key?(conn.assigns, :account)
    end

    test "halts if access/secret key are incorrect" do
      conn =
        build_conn()
        |> put_req_header("authorization", "OMGServer " <> Base.encode64(@access_key <> ":invalid_secret"))
        |> ProviderAuth.call([])

      assert conn.halted
      assert conn.status == 200
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :account)
    end
  end

  describe "V1.Plugs.ProviderAuth with Basic auth type" do
    test "assigns authenticated and account if access/secret key are correct" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Basic " <> Base.encode64(@access_key <> ":" <> @secret_key))
        |> ProviderAuth.call([])

      refute conn.halted
      assert conn.assigns[:authenticated]
      assert Map.has_key?(conn.assigns, :account)
    end

    test "halts if access/secret key are incorrect" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Basic " <> Base.encode64(@access_key <> ":invalid_secret"))
        |> ProviderAuth.call([])

      assert conn.halted
      assert conn.status == 200
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :account)
    end
  end

  describe "V1.Plugs.ProviderAuth" do
    test "halts if auth type is not supported" do
      conn =
        build_conn()
        |> put_req_header("authorization", "InvalidAuth " <> Base.encode64(@access_key <> ":" <> @secret_key))
        |> ProviderAuth.call([])

      assert conn.halted
      assert conn.status == 200
      refute conn.assigns[:authenticated]
      refute Map.has_key?(conn.assigns, :account)
    end
  end
end
