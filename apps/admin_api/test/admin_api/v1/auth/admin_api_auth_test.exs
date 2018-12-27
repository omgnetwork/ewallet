# Copyright 2018 OmiseGO Pte Ltd
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

defmodule AdminAPI.Web.V1.AdminAPIAuthTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.AdminAPIAuth
  alias EWalletDB.User

  def authenticate(scheme, user_id, token) do
    encoded_key = Base.encode64(user_id <> ":" <> token)

    AdminAPIAuth.authenticate(%{
      "headers" => [{"authorization", "#{scheme} #{encoded_key}"}]
    })
  end

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()

    %{
      user: user,
      auth_token: insert(:auth_token, user: user, owner_app: "admin_api"),
      key: insert(:key)
    }
  end

  describe "authenticate/1" do
    test "authenticates with OMGAdmin and valid credentials", meta do
      auth = authenticate("OMGAdmin", meta.user.id, meta.auth_token.token)

      assert auth.authenticated == true
      assert auth.auth_scheme == :admin
      assert auth.auth_scheme_name == "OMGAdmin"
      assert auth.admin_user.uuid == meta.user.uuid
      assert auth.auth_user_id == meta.user.id
      assert auth.auth_auth_token == meta.auth_token.token
    end

    test "authenticates with OMGProvider and valid credentials", meta do
      auth = authenticate("OMGProvider", meta.key.access_key, meta.key.secret_key)

      assert auth.authenticated == true
      assert auth.auth_scheme == :provider
      assert auth.auth_scheme_name == "OMGProvider"
      assert auth.key.id == meta.key.id
      assert auth.auth_access_key == meta.key.access_key
      assert auth.auth_secret_key == meta.key.secret_key
    end

    test "authenticates with Basic and valid credentials", meta do
      auth = authenticate("OMGProvider", meta.key.access_key, meta.key.secret_key)

      assert auth.authenticated == true
      assert auth.auth_scheme == :provider
      assert auth.auth_scheme_name == "OMGProvider"
      assert auth.key.id == meta.key.id
      assert auth.auth_access_key == meta.key.access_key
      assert auth.auth_secret_key == meta.key.secret_key
    end

    test "fails to authenticate with invalid sheme and data" do
      auth = authenticate("OMGFake", "one", "two")

      assert auth.authenticated == false
      assert auth.auth_error == :invalid_auth_scheme
    end

    test "fails to authenticate with invalid sheme" do
      auth =
        AdminAPIAuth.authenticate(%{
          headers: [{"authorization", "SomeAuth"}]
        })

      assert auth.authenticated == false
      assert auth.auth_error == :invalid_auth_scheme
    end
  end
end
