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

defmodule EWalletDB.Expirers.AuthExpirerTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWalletDB.Expirers.AuthExpirer
  alias EWalletDB.{AuthToken, PreAuthToken, Membership}

  @owner_app :some_app

  describe "get_new_expire_at/1" do
    test "returns nil when the lifetime is 0" do
      assert AuthExpirer.get_new_expire_at(0) == nil
    end

    test "returns NaiveDateTime with advanced by `lifetime` lifetime from the current date time" do
      lifetime = 60

      expire_at = AuthExpirer.get_new_expire_at(lifetime)
      expected_expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), lifetime, :second)

      assert NaiveDateTime.diff(expire_at, expected_expire_at, :second) == 0
    end
  end

  describe "expire_or_refresh/2" do
    test "returns nil if the given token is nil" do
      assert AuthExpirer.expire_or_refresh(nil, 30) == nil
    end

    test "returns an updated token with a correct expire_at if given AuthToken and non-zero lifetime" do
      user = insert(:user)
      %{token: token} = insert(:auth_token, user: user)

      # To include preloaded user
      auth_token = AuthToken.get_by_token(token, @some_app)

      IO.inspect(auth_token)

      assert auth_token == AuthExpirer.expire_or_refresh(auth_token, 30)
    end

    test "returns an updated token with a correct expire_at if given PreAuthToken and non-zero lifetime" do
      user = insert(:user)
      %{token: token} = insert(:auth_token)

      # To include preloaded user
      auth_token = AuthToken.get_by_token(token, @some_app)

      assert auth_token == AuthExpirer.expire_or_refresh(auth_token, 30)
    end
  end
end
