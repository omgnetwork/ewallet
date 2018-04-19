defmodule AdminAPI.V1.ClientAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.ClientAuthPlug
  alias Ecto.UUID

  describe "ClientAuthPlug.call/2" do
    test "assigns authenticated conn info when auth is not enabled" do
      conn = test_with_no_auth()
      refute conn.halted
      assert conn.assigns.authenticated == :client
    end

    test "assigns authenticated conn info if the api_key_id and api_key match the db record" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key)
      assert_success(conn)
    end

    test "assigns unauthenticated conn info if the api_key_id is not found" do
      conn = test_with("OMGAdmin", UUID.generate, @api_key)
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

  defp test_with(type, api_key_id, api_key), do: test_with(type, [api_key_id, api_key])
  defp test_with(type, data) when is_list(data) do
    build_conn()
    |> put_auth_header(type, data)
    |> ClientAuthPlug.call([])
  end

  defp test_with_no_auth do
    build_conn()
    |> ClientAuthPlug.call([enable_client_auth: false])
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
