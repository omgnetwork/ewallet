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
  import ActivityLogger.ActivityLoggerTestHelper
  alias EWalletDB.Expirers.AuthExpirer
  alias EWalletDB.{AuthToken, PreAuthToken}

  @owner_app :some_app

  setup context do
    case context do
      %{auth_token_lifetime: lifetime} when not is_nil(lifetime) ->
        Application.put_env(:ewallet_db, :auth_token_lifetime, lifetime)
        on_exit(fn -> Application.put_env(:ewallet_db, :auth_token_lifetime, 0) end)
        {:ok, lifetime: lifetime}

      %{pre_auth_token_lifetime: lifetime} when not is_nil(lifetime) ->
        Application.put_env(:ewallet_db, :pre_auth_token_lifetime, lifetime)
        on_exit(fn -> Application.put_env(:ewallet_db, :pre_auth_token_lifetime, 0) end)
        {:ok, lifetime: lifetime}

      _ ->
        :ok
    end
  end

  defp from_now_by_seconds(seconds) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), seconds, :second)
  end

  describe "get_advanced_datetime/1" do
    test "returns nil when the lifetime is 0" do
      assert AuthExpirer.get_advanced_datetime(0) == nil
    end

    test "returns an advanced NaiveDateTime when given a lifetime" do
      lifetime = 60

      expired_at = AuthExpirer.get_advanced_datetime(lifetime)
      expected_expired_at = NaiveDateTime.add(NaiveDateTime.utc_now(), lifetime, :second)

      assert NaiveDateTime.diff(expired_at, expected_expired_at, :second) in -3..3
    end
  end

  describe "expire_or_refresh/2" do
    test "returns nil if the given token is nil" do
      assert AuthExpirer.expire_or_refresh(nil, 30) == nil
    end

    test "returns a given token if a given auth_token_lifetime is zero" do
      auth_token = insert(:auth_token)
      assert AuthExpirer.expire_or_refresh(auth_token, 0) == auth_token
    end

    @tag auth_token_lifetime: 30
    test "returns an auth_token with a renewed `expired_at` if given positive integer and nil to `auth_token_lifetime` and `expired_at` respectively",
         context do
      auth_token = insert(:auth_token)
      %{expired_at: expired_at} = AuthExpirer.expire_or_refresh(auth_token, context.lifetime)
      expected_expired_at = NaiveDateTime.add(NaiveDateTime.utc_now(), context.lifetime)
      assert NaiveDateTime.diff(expired_at, expected_expired_at) == 0
    end

    test "returns a pre_auth_token with a renewed expired_at if given positive integer and nil to `pre_auth_token_lifetime` and `expired_at` respectively" do
      %{token: token} = insert(:pre_auth_token)

      # To include preloaded user
      auth_token = PreAuthToken.get_by_token(token, @owner_app)

      assert auth_token == AuthExpirer.expire_or_refresh(auth_token, 30)
    end

    @tag auth_token_lifetime: 7200
    test "returns an auth_token with a renewed `expired_at` if given positive `auth_token_lifetime` and `expired_at` has not been lapsed",
         context do
      user = insert(:user)
      expired_at = from_now_by_seconds(3600)
      before_expire_or_refresh = from_now_by_seconds(0)

      auth_token =
        insert(:auth_token, %{expired_at: expired_at, user: user, owner_app: "some_app"})

      refreshed_auth_token =
        auth_token.token
        |> AuthToken.get_by_token(@owner_app)
        |> AuthExpirer.expire_or_refresh(context.lifetime)

      expected_expired_at = AuthExpirer.get_advanced_datetime(context.lifetime)
      assert NaiveDateTime.diff(refreshed_auth_token.expired_at, expected_expired_at) == 0

      # Assert there's no activity logs are recorded.
      assert get_all_activity_logs_since(before_expire_or_refresh) == []
    end

    @tag pre_auth_token_lifetime: 7200
    test "returns a pre_auth_token with a renewed `expired_at` if given positive `pre_auth_token_lifetime` and `expired_at` has not been lapsed",
         context do
      user = insert(:user)
      expired_at = from_now_by_seconds(3600)
      before_expire_or_refresh = from_now_by_seconds(0)

      pre_auth_token =
        insert(:pre_auth_token, %{expired_at: expired_at, user: user, owner_app: "some_app"})

      refreshed_pre_auth_token =
        pre_auth_token.token
        |> PreAuthToken.get_by_token(@owner_app)
        |> AuthExpirer.expire_or_refresh(context.lifetime)

      expected_expired_at = AuthExpirer.get_advanced_datetime(context.lifetime)
      assert NaiveDateTime.diff(refreshed_pre_auth_token.expired_at, expected_expired_at) == 0

      # Assert there's no activity logs are recorded.
      assert get_all_activity_logs_since(before_expire_or_refresh) == []
    end

    test "returns an expired auth_token if a given auth_token's expired_at has been lapsed " do
      # Set expired_at to 1 hr ago.
      expired_at = from_now_by_seconds(-3600)
      before_expire_or_refresh = from_now_by_seconds(0)

      auth_token =
        :auth_token
        |> insert(%{expired_at: expired_at})
        |> AuthExpirer.expire_or_refresh(30)

      assert auth_token.expired == true

      # Assert there's 1 activity log.
      assert [log] = get_all_activity_logs_since(before_expire_or_refresh)

      # Assert `expired` is changed to true
      assert log.target_changes == %{"expired" => true}
    end

    @tag auth_token_lifetime: 7200
    test "returns an expired pre_auth_token if a given pre_auth_token's expired_at has been lapsed" do
      # Set expired_at to 1 hr ago.
      expired_at = from_now_by_seconds(-3600)
      before_expire_or_refresh = from_now_by_seconds(0)

      pre_auth_token =
        :pre_auth_token
        |> insert(%{expired_at: expired_at})
        |> AuthExpirer.expire_or_refresh(30)

      assert pre_auth_token.expired == true

      # Assert there's 1 activity log.
      assert [log] = get_all_activity_logs_since(before_expire_or_refresh)

      # Assert `expired` is changed to true
      assert log.target_changes == %{"expired" => true}
    end
  end
end
