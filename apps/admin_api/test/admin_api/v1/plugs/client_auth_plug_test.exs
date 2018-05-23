defmodule AdminAPI.V1.ClientAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.ClientAuthPlug
  alias Ecto.UUID

  describe "ClientAuthPlug.call/2 with enable_client_auth == true" do
    test "assigns authenticated conn info if the api_key_id and api_key match the db record" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key)
      assert_success(conn)
    end

    test "assigns unauthenticated conn info if the api_key_id is not found" do
      conn = test_with("OMGAdmin", UUID.generate(), @api_key)
      assert_error(conn)
    end

    test "assigns unauthenticated conn info if the api_key is not found" do
      conn = test_with("OMGAdmin", @api_key_id, "wrong_api_key")
      assert_error(conn)
    end

    test "assigns unauthenticated conn info if the api_key_id is not provided" do
      conn = test_with("OMGAdmin", nil, @api_key)
      assert_error(conn)

      conn = test_with("OMGAdmin", "", @api_key)
      assert_error(conn)
    end

    test "assigns unauthenticated conn info if the api_key is not provided" do
      conn = test_with("OMGAdmin", @api_key_id, nil)
      assert_error(conn)

      conn = test_with("OMGAdmin", @api_key_id, "")
      assert_error(conn)
    end

    test "assigns unauthenticated conn info if the api_key_id and api_key are not provided" do
      conn = test_with("OMGAdmin", nil, nil)
      assert_error(conn)

      conn = test_with("OMGAdmin", "", "")
      assert_error(conn)
    end
  end

  describe "ClientAuthPlug.call/2 with enable_client_auth == false" do
    test "assigns authenticated == :client" do
      conn = test_with("OMGAdmin", "", "", false)
      refute conn.halted
      assert conn.assigns.authenticated == :client
    end
  end

  defp test_with(type, api_key_id, api_key, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [api_key_id, api_key])
    |> ClientAuthPlug.call(enable_client_auth: client_auth?)
  end

  defp assert_success(conn) do
    refute conn.halted
    assert conn.assigns.authenticated == :client
    assert conn.assigns.api_key_id == @api_key_id
  end

  defp assert_error(conn) do
    assert conn.halted
    assert conn.assigns.authenticated == false
    refute Map.has_key?(conn.assigns, :api_key_id)
    refute Map.has_key?(conn.assigns, :account)
  end
end
