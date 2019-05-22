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
  use EWalletDB.SchemaCase
  import EWalletDB.Factory
  alias EWalletDB.Expirers.AuthExpirer
  alias EWalletDB.{AuthToken, PreAuthToken}

  @owner_app :some_app

  setup context do
    case context do
      %{atk_lifetime: lifetime} when not is_nil(lifetime) ->
        Application.put_env(:ewallet, :atk_lifetime, lifetime)
        on_exit(fn -> Application.put_env(:ewallet, :atk_lifetime, 0) end)
        {:ok, lifetime: lifetime}

      %{ptk_lifetime: lifetime} when not is_nil(lifetime) ->
        Application.put_env(:ewallet, :ptk_lifetime, lifetime)
        on_exit(fn -> Application.put_env(:ewallet, :ptk_lifetime, 0) end)
        {:ok, lifetime: lifetime}

      _ ->
        :ok
    end
  end

  describe "get_advanced_datetime/1" do
    test "returns nil when the lifetime is 0" do
      assert AuthExpirer.get_advanced_datetime(0) == nil
    end

    test "returns an advanced NaiveDateTime when given a lifetime" do
      lifetime = 60

      expire_at = AuthExpirer.get_advanced_datetime(lifetime)
      expected_expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), lifetime, :second)

      assert NaiveDateTime.diff(expire_at, expected_expire_at, :second) == 0
    end
  end

  describe "expire_or_refresh/2" do
    test "returns nil if the given token is nil" do
      assert AuthExpirer.expire_or_refresh(nil, 30) == nil
    end

    test "returns a given token if a given atk_lifetime is zero" do
      auth_token = insert(:auth_token)
      assert AuthExpirer.expire_or_refresh(auth_token, 0) == auth_token
    end

    @tag atk_lifetime: 30
    test "returns an auth_token with a renewed `expire_at` if given non-zero integer and nil to `atk_lifetime` and `expire_at` respectively",
         context do
      auth_token = insert(:auth_token)
      %{expire_at: expire_at} = AuthExpirer.expire_or_refresh(auth_token, context.lifetime)
      expected_expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), context.lifetime)
      assert NaiveDateTime.diff(expire_at, expected_expire_at) == 0
    end

    test "returns a pre_auth_token with a renewed expire_at if given non-zero integer and nil to `ptk_lifetime` and `expire_at` respectively" do
      %{token: token} = insert(:pre_auth_token)

      # To include preloaded user
      auth_token = PreAuthToken.get_by_token(token, @owner_app)

      assert auth_token == AuthExpirer.expire_or_refresh(auth_token, 30)
    end

    @tag atk_lifetime: 7200
    test "returns an auth_token with a renewed `expire_at` if given non-zero `atk_lifetime` and `expire_at` has not been lapsed",
         context do
      user = insert(:user)
      expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      auth_token = insert(:auth_token, %{expire_at: expire_at, user: user, owner_app: "some_app"})

      refreshed_auth_token =
        auth_token.token
        |> AuthToken.get_by_token(@owner_app)
        |> AuthExpirer.expire_or_refresh(context.lifetime)

      expected_expire_at = AuthExpirer.get_advanced_datetime(context.lifetime)
      assert NaiveDateTime.diff(refreshed_auth_token.expire_at, expected_expire_at) == 0
    end

    @tag ptk_lifetime: 7200
    test "returns a pre_auth_token with a renewed `expire_at` if given non-zero `ptk_lifetime` and `expire_at` has not been lapsed",
         context do
      user = insert(:user)
      expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600)

      pre_auth_token =
        insert(:pre_auth_token, %{expire_at: expire_at, user: user, owner_app: "some_app"})

      refreshed_pre_auth_token =
        pre_auth_token.token
        |> PreAuthToken.get_by_token(@owner_app)
        |> AuthExpirer.expire_or_refresh(context.lifetime)

      expected_expire_at = AuthExpirer.get_advanced_datetime(context.lifetime)
      assert NaiveDateTime.diff(refreshed_pre_auth_token.expire_at, expected_expire_at) == 0
    end

    test "returns an expired auth_token if a given auth_token's expire_at has been lapsed " do
      # Set expire_at to 1 hr ago.
      expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -3600)

      auth_token =
        :auth_token
        |> insert(%{expire_at: expire_at})
        |> AuthExpirer.expire_or_refresh(30)

      assert auth_token.expired == true
    end

    @tag atk_lifetime: 7200
    test "returns an expired pre_auth_token if a given pre_auth_token's expire_at has been lapsed" do
      # Set expire_at to 1 hr ago.
      expire_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -3600)

      pre_auth_token =
        :pre_auth_token
        |> insert(%{expire_at: expire_at})
        |> AuthExpirer.expire_or_refresh(30)

      assert pre_auth_token.expired == true
    end
  end
end
