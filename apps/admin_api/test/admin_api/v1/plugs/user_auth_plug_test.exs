defmodule AdminAPI.V1.UserAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.UserAuthPlug
  alias Ecto.UUID

  describe "UserAuthPlug.call/2" do
    test "assigns authenticated conn info if the token is correct without admin " do
      conn = test_with("OMGAdmin", @user_id, @auth_token)

      refute conn.halted
      assert_success(conn)
    end

    test "assigns authenticated conn info if the token is correct" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, @user_id, @auth_token)

      refute conn.halted
      assert_success(conn)
    end

    test "assigns unauthenticated conn info if the token is invalid" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, @user_id, "bad_token")

      assert conn.halted
      assert_error(conn)
    end

    test "assigns unauthenticated conn info if the token doesn't belong to the user_id" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, UUID.generate, @auth_token)

      assert conn.halted
      assert_error(conn)
    end
  end

  describe "UserAuthPlug.authenticate/3" do
    test "returns conn with the user and authenticated:true if email and password are valid" do
      conn = UserAuthPlug.authenticate(build_conn(), @user_email, @password)
      assert_success(conn)
    end

    test "returns conn with authenticated:false if email is invalid" do
      conn = UserAuthPlug.authenticate(build_conn(), "wrong@example.com", @password)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is invalid" do
      conn = UserAuthPlug.authenticate(build_conn(), @user_email, "wrong_password")
      assert_error(conn)
    end

    test "returns conn with authenticated:false if both email and password are invalid" do
      conn = UserAuthPlug.authenticate(build_conn(), "wrong@example.com", "wrong_password")
      assert_error(conn)
    end

    test "returns conn with authenticated:false if email is missing" do
      conn = UserAuthPlug.authenticate(build_conn(), nil, @password)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is missing" do
      conn = UserAuthPlug.authenticate(build_conn(), @user_email, nil)
      assert_error(conn)
    end

    test "returns conn with authenticated:false both email and password are missing" do
      conn = UserAuthPlug.authenticate(build_conn(), nil, nil)
      assert_error(conn)
    end
  end

  defp test_with(type, api_key_id, api_key, user_id, auth_token) do
    build_conn()
    |> put_auth_header(type, [api_key_id, api_key, user_id, auth_token])
    |> UserAuthPlug.call([])
  end

  defp test_with(type, user_id, auth_token) do
    build_conn()
    |> put_auth_header(type, [user_id, auth_token])
    |> UserAuthPlug.call([enable_client_auth: false])
  end

  defp assert_success(conn) do
    assert conn.assigns.authenticated == :user
    assert conn.assigns.user.uuid == get_test_user().uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :user)
  end
end
