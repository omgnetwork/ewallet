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

defmodule EWalletDB.PreAuthTokenTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWalletDB.{PreAuthToken, Membership, Repo}

  @owner_app :some_app

  setup context do
    case context do
      %{pre_auth_token_lifetime: second} when not is_nil(second) ->
        Application.put_env(:ewallet_db, :pre_auth_token_lifetime, second)
        on_exit(fn -> Application.put_env(:ewallet_db, :pre_auth_token_lifetime, 0) end)
        {:ok, second: second}

      _ ->
        :ok
    end
  end

  defp from_now_by_seconds(seconds) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), seconds, :second)
  end

  defp insert_ptk(attrs) do
    attrs =
      Map.merge(
        %{
          user: insert(:user),
          owner_app: Atom.to_string(@owner_app),
          expired_at: from_now_by_seconds(60)
        },
        attrs
      )

    insert(:pre_auth_token, attrs)
  end

  describe "PreAuthToken.generate/3" do
    test "generates a pre_auth_token string with length == 43" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      assert {:ok, pre_auth_token} = PreAuthToken.generate(user, @owner_app, %System{})
      assert String.length(pre_auth_token.token) == 43
    end

    @tag pre_auth_token_lifetime: 3600
    test "generates a pre_auth_token with a correct expired_at when set a positive integer to pre_auth_token_lifetime",
         context do
      user = insert(:user)

      assert {:ok, pre_auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      # Expect expired_at is at next 60 minutes.
      expire_at_diff =
        context.second
        |> from_now_by_seconds()
        |> NaiveDateTime.diff(pre_auth_token.expired_at, :second)

      assert expire_at_diff in -3..3
    end

    @tag pre_auth_token_lifetime: 0
    test "generates a pre_auth_token with expired_at nil when set zero to pre_auth_token_lifetime" do
      user = insert(:user)

      assert {:ok, pre_auth_token} = PreAuthToken.generate(user, @owner_app, %System{})
      assert pre_auth_token.expired_at == nil
    end

    test "returns error if user is invalid" do
      account = insert(:account)
      {res, reason} = PreAuthToken.generate(account, @owner_app, %System{})

      assert res == :error
      assert reason == :invalid_parameter
    end

    test "allows multiple pre_auth_tokens for each user" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, token1} = PreAuthToken.generate(user, @owner_app, %System{})
      {:ok, token2} = PreAuthToken.generate(user, @owner_app, %System{})

      token_count =
        user
        |> Ecto.assoc(:pre_auth_tokens)
        |> Repo.aggregate(:count, :id)

      assert String.length(token1.token) > 0
      assert String.length(token2.token) > 0
      assert token_count == 2
    end
  end

  describe "PreAuthToken.authenticate/2" do
    test "returns an existing pre_auth_token if exists" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, pre_auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      pre_auth_token = PreAuthToken.authenticate(pre_auth_token.token, @owner_app)
      assert pre_auth_token.user.uuid == user.uuid
    end

    @tag pre_auth_token_lifetime: 3600
    test "returns a user if the pre_auth_token exists and the expired_at has not been lapsed",
         context do
      # The user has the pre authentication token which will be expired in a minute.
      %{token: token} = insert_ptk(%{expired_at: from_now_by_seconds(60)})

      # The user authenticated while the :pre_auth_token_lifetime has been set to 60 minutes
      pre_auth_token = PreAuthToken.authenticate(token, @owner_app)

      # Expect expired_at is refreshed and it is set to the next hour.
      expire_at_diff =
        context.second
        |> from_now_by_seconds()
        |> NaiveDateTime.diff(pre_auth_token.expired_at, :second)

      assert expire_at_diff in -3..3
    end

    @tag pre_auth_token_lifetime: 0
    test "returns pre_auth_token with expired_at: nil when pre_auth_token_lifetime is 0" do
      %{token: token_1, user: user_1} = insert_ptk(%{expired_at: nil})

      %{token: token_2, user: user_2, expired_at: _} =
        insert_ptk(%{expired_at: from_now_by_seconds(60)})

      pre_auth_token_1 = PreAuthToken.authenticate(token_1, @owner_app)
      pre_auth_token_2 = PreAuthToken.authenticate(token_2, @owner_app)

      assert pre_auth_token_1.user.uuid == user_1.uuid
      assert pre_auth_token_2.user.uuid == user_2.uuid
      assert pre_auth_token_1.expired_at == nil
      assert pre_auth_token_2.expired_at == nil
    end

    @tag pre_auth_token_lifetime: 0
    test "returns {:error, :token_expired} when expired_at has lapsed and the pre_auth_token_lifetime is 0" do
      %{token: token, user: _} = insert_ptk(%{expired_at: from_now_by_seconds(-60)})

      assert PreAuthToken.authenticate(token, @owner_app) == {:error, :token_expired}
    end

    @tag pre_auth_token_lifetime: 3600
    test "returns :token_expired if the pre_auth_token exists and the expired_at has been lapsed" do
      attrs = %{owner_app: Atom.to_string(@owner_app), expired_at: from_now_by_seconds(0)}

      token = insert(:pre_auth_token, attrs)

      assert PreAuthToken.authenticate(token.token, @owner_app) == {:error, :token_expired}
    end

    test "returns false if pre_auth_token exists but for a different owner app" do
      token = insert(:pre_auth_token, %{owner_app: "wrong_app"})

      assert PreAuthToken.authenticate(token.token, @owner_app) == {:error, :token_not_found}
    end

    test "returns false if token does not exists" do
      assert PreAuthToken.authenticate("unmatched", @owner_app) == {:error, :token_not_found}
    end

    test "returns false if pre_auth_token is nil" do
      assert PreAuthToken.authenticate(nil, @owner_app) == {:error, :token_not_found}
    end
  end

  describe "PreAuthToken.authenticate/3" do
    test "returns an existing pre_auth_token if user_id and token match" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, pre_auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      pre_auth_token = PreAuthToken.authenticate(user.id, pre_auth_token.token, @owner_app)
      assert pre_auth_token.user.uuid == user.uuid
    end

    test "returns an existing pre_auth_token if user_id and token are matched and the user has multiple pre_auth_tokens" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, token1} = PreAuthToken.generate(user, @owner_app, %System{})
      {:ok, token2} = PreAuthToken.generate(user, @owner_app, %System{})

      assert PreAuthToken.authenticate(user.id, token1.token, @owner_app)
      assert PreAuthToken.authenticate(user.id, token2.token, @owner_app)
    end

    @tag pre_auth_token_lifetime: 3600
    test "returns a user if the expired_at has not been lapsed", context do
      user = insert(:user)

      # The authentication token which will be expired in the next minute.
      attrs = %{
        owner_app: Atom.to_string(@owner_app),
        expired_at: from_now_by_seconds(60),
        user: user
      }

      pre_auth_token = insert(:pre_auth_token, attrs)

      # The user authenticate to the system,
      # while the :pre_auth_token_lifetime has been set to 60 minutes
      pre_auth_token = PreAuthToken.authenticate(pre_auth_token.token, @owner_app)

      assert pre_auth_token.user.uuid == user.uuid

      # Assert the token has been refreshed.
      updated_auth_token = PreAuthToken.get_by_token(pre_auth_token.token, @owner_app)

      # Expect expired_at is next 60 minutes from now.
      expire_at_diff =
        context.second
        |> from_now_by_seconds()
        |> NaiveDateTime.diff(updated_auth_token.expired_at, :second)

      assert expire_at_diff in -3..3
    end

    test "returns a user if the expired_at is nil" do
      user = insert(:user)
      attrs = %{owner_app: Atom.to_string(@owner_app), expired_at: nil, user: user}
      token = insert(:pre_auth_token, attrs)

      pre_auth_token = PreAuthToken.authenticate(user.id, token.token, @owner_app)
      assert pre_auth_token.user.uuid == user.uuid
    end

    @tag pre_auth_token_lifetime: 3600
    test "returns :token_expired if the expired_at has been lapsed" do
      user = insert(:user)

      attrs = %{
        owner_app: Atom.to_string(@owner_app),
        user: user,
        expired_at: from_now_by_seconds(-60)
      }

      pre_auth_token = insert(:pre_auth_token, attrs)

      assert PreAuthToken.authenticate(user.id, pre_auth_token.token, @owner_app) ==
               {:error, :token_expired}
    end

    test "returns false if pre_auth_token belongs to a different user" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, pre_auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      another_user = insert(:admin)

      assert PreAuthToken.authenticate(another_user.id, pre_auth_token.token, @owner_app) ==
               {:error, :token_not_found}
    end

    test "returns false if pre_auth_token exists but for a different owner app" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, pre_auth_token} = PreAuthToken.generate(user, :different_app, %System{})

      assert PreAuthToken.authenticate(user.id, pre_auth_token.token, @owner_app) ==
               {:error, :token_not_found}
    end

    test "returns false if pre_auth_token does not exists" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, _} = PreAuthToken.generate(user, @owner_app, %System{})

      assert PreAuthToken.authenticate(user.id, "unmatched", @owner_app) ==
               {:error, :token_not_found}
    end

    test "returns false if pre_auth_token is nil" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, _} = PreAuthToken.generate(user, @owner_app, %System{})

      assert PreAuthToken.authenticate(user.id, nil, @owner_app) == {:error, :token_not_found}
    end
  end

  describe "PreAuthToken.get_lifetime/0" do
    test "returns 0 by default" do
      assert PreAuthToken.get_lifetime() == 0
    end

    @tag pre_auth_token_lifetime: 60
    test "returns a given value", context do
      assert PreAuthToken.get_lifetime() == context.second
    end
  end
end
