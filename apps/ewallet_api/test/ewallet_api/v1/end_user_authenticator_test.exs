# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.Web.V1.EndUserAuthenticatorTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletAPI.V1.EndUserAuthenticator
  alias Utils.Helpers.Crypto
  alias EWalletDB.User
  alias ActivityLogger.System

  setup do
    email = "end_user_auth@example.com"
    password = "some_password"

    user =
      insert(:user, %{email: email, password_hash: Crypto.hash_password(password), enabled: true})

    %{
      email: email,
      password: password,
      user: user
    }
  end

  describe "authenticate/3" do
    test "returns conn with the user and authenticated:true if email and password are valid",
         context do
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, context.password)
      assert_success(conn, context)
    end

    test "returns conn with authenticated:false if email is invalid", context do
      conn =
        EndUserAuthenticator.authenticate(build_conn(), "wrong@example.com", context.password)

      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is invalid", context do
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, "wrong_password")
      assert_error(conn)
    end

    test "returns conn with authenticated:false if both email and password are invalid",
         _context do
      conn =
        EndUserAuthenticator.authenticate(build_conn(), "wrong@example.com", "wrong_password")

      assert_error(conn)
    end

    test "returns conn with authenticated:false if email is missing", context do
      conn = EndUserAuthenticator.authenticate(build_conn(), nil, context.password)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is missing", context do
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, nil)
      assert_error(conn)
    end

    test "returns conn with authenticated:false both email and password are missing", _context do
      conn = EndUserAuthenticator.authenticate(build_conn(), nil, nil)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if user is disabled", context do
      {:ok, _} = User.enable_or_disable(context.user, %{enabled: false, originator: %System{}})
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, context.password)
      assert_error(conn)
    end
  end

  defp assert_success(conn, context) do
    assert conn.assigns.authenticated == true
    assert conn.assigns.end_user.uuid == context.user.uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :end_user)
  end
end
