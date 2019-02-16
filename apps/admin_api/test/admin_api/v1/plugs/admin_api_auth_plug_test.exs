# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.AdminAPIAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.AdminAPIAuthPlug

  describe "AdminAPIAuthPlug.call/2 with provider auth" do
    test "authenticates if both access key and secret key are correct" do
      conn = test_with("OMGProvider", @access_key, Base.url_encode64(@secret_key))

      refute conn.halted
      assert conn.assigns.authenticated == true
      assert conn.assigns.auth_scheme == :provider
      assert conn.assigns[:admin_user] == nil
      assert conn.private[:auth_access_key] == @access_key
    end

    test "fails to authenticate if an invalid access key is provided" do
      conn = test_with("OMGProvider", "fake", @secret_key)

      assert conn.halted
      assert conn.assigns.authenticated == false
    end

    test "fails to authenticate if an invalid secret key is provided" do
      conn = test_with("OMGProvider", @access_key, "fake")

      assert conn.halted
      assert conn.assigns.authenticated == false
    end

    test "halts the conn when authorization header is not provided" do
      conn = AdminAPIAuthPlug.call(build_conn(), nil)

      assert conn.halted
      assert conn.assigns.authenticated == false
    end
  end

  describe "AdminAPIAuthPlug.call/2 with enable_client_auth is false" do
    test "authenticates if user credentials are correct " do
      conn = test_with("OMGAdmin", @admin_id, @auth_token, false)

      refute conn.halted
      assert_success(conn)
    end

    test "halts if user credentials are incorrect (token)" do
      conn = test_with("OMGAdmin", @admin_id, "bad_token", false)

      assert conn.halted
      assert_error(conn)
    end

    test "halts if user credentials are incorrect (admin user id)" do
      conn = test_with("OMGAdmin", "fake", @auth_token, false)

      assert conn.halted
      assert_error(conn)
    end
  end

  defp test_with(type, user_id, auth_token, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [user_id, auth_token])
    |> AdminAPIAuthPlug.call(enable_client_auth: client_auth?)
  end

  defp assert_success(conn) do
    assert conn.assigns.authenticated == true
    assert conn.assigns.auth_scheme == :admin
    assert conn.assigns.admin_user.uuid == get_test_admin().uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :admin_user)
  end
end
