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

  defp set_token_lifetime(minute) do
    Application.put_env(:ewallet, :pre_auth_token_lifetime, minute)
  end

  defp from_now_by_seconds(seconds) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), seconds, :second)
  end

  describe "PreAuthToken.generate/3" do
    test "generates an pre auth token string with length == 43" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {res, auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      assert res == :ok
      assert String.length(auth_token.token) == 43
    end

    test "generates an auth token with a correct expire_at when set a positive integer to auth_token_lifetime" do
      user = insert(:user)

      set_token_lifetime(60)

      assert {:ok, auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      # Expect expire_at is next 60 minutes from now, with a precision down to a second.
      assert (60 * 60)
             |> from_now_by_seconds()
             |> NaiveDateTime.diff(auth_token.expire_at, :second)
             |> Kernel.floor() == 0
    end

    test "generates an auth token with expire_at nil when set zero to auth_token_lifetime" do
      user = insert(:user)

      set_token_lifetime(0)

      assert {:ok, auth_token} = PreAuthToken.generate(user, @owner_app, %System{})
      assert auth_token.expire_at == nil
    end

    test "returns error if user is invalid" do
      account = insert(:account)
      {res, reason} = PreAuthToken.generate(account, @owner_app, %System{})

      assert res == :error
      assert reason == :invalid_parameter
    end

    test "allows multiple auth tokens for each user" do
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
    test "returns an existing token if exists" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      auth_token = PreAuthToken.authenticate(auth_token.token, @owner_app)
      assert auth_token.user.uuid == user.uuid
    end

    test "returns a user if the token exists and the current date time is before expire_at" do
      # Set the auth token lifetime to 1 hour.
      set_token_lifetime(60)

      user = insert(:user)

      auth_token =
        insert(:pre_auth_token, %{
          owner_app: Atom.to_string(@owner_app),
          expire_at: from_now_by_seconds(15),
          user: user
        })

      auth_token = PreAuthToken.authenticate(auth_token.token, @owner_app)
      assert auth_token.user.uuid == user.uuid

      # Assert the token has been refreshed.
      updated_auth_token = PreAuthToken.get_by_token(auth_token.token, @owner_app)

      # Expect expire_at is next 60 minutes from now, with a precision down to a second.
      assert (60 * 60)
             |> from_now_by_seconds
             |> NaiveDateTime.diff(updated_auth_token.expire_at, :second)
             |> Kernel.floor() == 0
    end

    test "returns a user if the token exists and the expire_at is nil" do
      user = insert(:user)
      attrs = %{owner_app: Atom.to_string(@owner_app), expire_at: nil, user: user}
      token = insert(:pre_auth_token, attrs)

      auth_token = PreAuthToken.authenticate(token.token, @owner_app)
      assert auth_token.user.uuid == user.uuid
    end

    test "returns :token_expired if the token exists and the current date time is after expire_at" do
      attrs = %{owner_app: Atom.to_string(@owner_app), expire_at: NaiveDateTime.utc_now()}

      token = insert(:pre_auth_token, attrs)

      assert PreAuthToken.authenticate(token.token, @owner_app) == :token_expired
    end

    test "returns false if token exists but for a different owner app" do
      token = insert(:pre_auth_token, %{owner_app: "wrong_app"})

      assert PreAuthToken.authenticate(token.token, @owner_app) == false
    end

    test "returns false if token does not exists" do
      assert PreAuthToken.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if auth token is nil" do
      assert PreAuthToken.authenticate(nil, @owner_app) == false
    end
  end

  describe "PreAuthToken.authenticate/3" do
    test "returns an existing token if user_id and token match" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      auth_token = PreAuthToken.authenticate(user.id, auth_token.token, @owner_app)
      assert auth_token.user.uuid == user.uuid
    end

    test "returns an existing token if user_id and token match and user has multiple tokens" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, token1} = PreAuthToken.generate(user, @owner_app, %System{})
      {:ok, token2} = PreAuthToken.generate(user, @owner_app, %System{})

      assert PreAuthToken.authenticate(user.id, token1.token, @owner_app)
      assert PreAuthToken.authenticate(user.id, token2.token, @owner_app)
    end

    test "returns a user if the current date time is before expire_at" do
      # Set the auth token lifetime to 60 minutes.
      set_token_lifetime(60)

      user = insert(:user)

      pre_auth_token =
        insert(:pre_auth_token, %{
          owner_app: Atom.to_string(@owner_app),
          expire_at: from_now_by_seconds(60 * 60),
          user: user
        })

      pre_auth_token = PreAuthToken.authenticate(user.id, pre_auth_token.token, @owner_app)
      assert pre_auth_token.user.uuid == user.uuid

      # Assert the token has been refreshed.
      updated_auth_token = PreAuthToken.get_by_token(pre_auth_token.token, @owner_app)

      # Expect expire_at is next 60 minutes from now, with a precision down to a second.
      assert (60 * 60)
             |> from_now_by_seconds
             |> NaiveDateTime.diff(updated_auth_token.expire_at, :second)
             |> Kernel.floor() == 0
    end

    test "returns a user if the expire_at is nil" do
      user = insert(:user)
      attrs = %{owner_app: Atom.to_string(@owner_app), expire_at: nil, user: user}
      token = insert(:pre_auth_token, attrs)

      auth_token = PreAuthToken.authenticate(user.id, token.token, @owner_app)
      assert auth_token.user.uuid == user.uuid
    end

    test "returns :token_expired if the current date time is after expire_at" do
      attrs = %{owner_app: Atom.to_string(@owner_app), expire_at: NaiveDateTime.utc_now()}

      token = insert(:pre_auth_token, attrs)

      assert PreAuthToken.authenticate(token.token, @owner_app) == :token_expired
    end

    test "returns false if auth token belongs to a different user" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, auth_token} = PreAuthToken.generate(user, @owner_app, %System{})

      another_user = insert(:admin)
      assert PreAuthToken.authenticate(another_user.id, auth_token.token, @owner_app) == false
    end

    test "returns false if token exists but for a different owner app" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, auth_token} = PreAuthToken.generate(user, :different_app, %System{})

      assert PreAuthToken.authenticate(user.id, auth_token.token, @owner_app) == false
    end

    test "returns false if token does not exists" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, _} = PreAuthToken.generate(user, @owner_app, %System{})

      assert PreAuthToken.authenticate(user.id, "unmatched", @owner_app) == false
    end

    test "returns false if token is nil" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, _} = PreAuthToken.generate(user, @owner_app, %System{})

      assert PreAuthToken.authenticate(user.id, nil, @owner_app) == false
    end
  end
end
