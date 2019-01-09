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

defmodule EWalletDB.AuthTokenTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWalletDB.{AuthToken, Membership, Repo}

  @owner_app :some_app

  describe "AuthToken.generate/1" do
    test "generates an auth token string with length == 43" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {res, auth_token} = AuthToken.generate(user, @owner_app, %System{})

      assert res == :ok
      assert String.length(auth_token.token) == 43
    end

    test "returns error if user is invalid" do
      account = insert(:account)
      {res, reason} = AuthToken.generate(account, @owner_app, %System{})

      assert res == :error
      assert reason == :invalid_parameter
    end

    test "allows multiple auth tokens for each user" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, token1} = AuthToken.generate(user, @owner_app, %System{})
      {:ok, token2} = AuthToken.generate(user, @owner_app, %System{})

      token_count =
        user
        |> Ecto.assoc(:auth_tokens)
        |> Repo.aggregate(:count, :id)

      assert String.length(token1.token) > 0
      assert String.length(token2.token) > 0
      assert token_count == 2
    end
  end

  describe "AuthToken.authenticate/2" do
    test "returns an existing token if exists" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, auth_token} = AuthToken.generate(user, @owner_app, %System{})

      auth_user = AuthToken.authenticate(auth_token.token, @owner_app)
      assert auth_user.uuid == user.uuid
    end

    test "returns :token_expired if token exists but expired" do
      {:ok, token} =
        :auth_token
        |> insert(%{owner_app: Atom.to_string(@owner_app)})
        |> AuthToken.expire(%System{})

      assert AuthToken.authenticate(token.token, @owner_app) == :token_expired
    end

    test "returns false if token exists but for a different owner app" do
      {:ok, token} =
        :auth_token
        |> insert(%{owner_app: "wrong_app"})
        |> AuthToken.expire(%System{})

      assert AuthToken.authenticate(token.token, @owner_app) == false
    end

    test "returns false if token does not exists" do
      assert AuthToken.authenticate("unmatched", @owner_app) == false
    end

    test "returns false if auth token is nil" do
      assert AuthToken.authenticate(nil, @owner_app) == false
    end
  end

  describe "AuthToken.authenticate/3" do
    test "returns an existing token if user_id and token match" do
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, auth_token} = AuthToken.generate(user, @owner_app, %System{})

      auth_user = AuthToken.authenticate(user.id, auth_token.token, @owner_app)
      assert auth_user.uuid == user.uuid
    end

    test "returns an existing token if user_id and token match and user has multiple tokens" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, token1} = AuthToken.generate(user, @owner_app, %System{})
      {:ok, token2} = AuthToken.generate(user, @owner_app, %System{})

      assert AuthToken.authenticate(user.id, token1.token, @owner_app)
      assert AuthToken.authenticate(user.id, token2.token, @owner_app)
    end

    test "returns :token_expired if token exists but expired" do
      token = insert(:auth_token, %{owner_app: Atom.to_string(@owner_app)})
      AuthToken.expire(token, %System{})

      assert AuthToken.authenticate(token.user.id, token.token, @owner_app) == :token_expired
    end

    test "returns false if auth token belongs to a different user" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, auth_token} = AuthToken.generate(user, @owner_app, %System{})

      another_user = insert(:admin)
      assert AuthToken.authenticate(another_user.id, auth_token.token, @owner_app) == false
    end

    test "returns false if token exists but for a different owner app" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, auth_token} = AuthToken.generate(user, :different_app, %System{})

      assert AuthToken.authenticate(user.id, auth_token.token, @owner_app) == false
    end

    test "returns false if token does not exists" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, _} = AuthToken.generate(user, @owner_app, %System{})

      assert AuthToken.authenticate(user.id, "unmatched", @owner_app) == false
    end

    test "returns false if auth token is nil" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})
      {:ok, _} = AuthToken.generate(user, @owner_app, %System{})

      assert AuthToken.authenticate(user.id, nil, @owner_app) == false
    end
  end

  describe "AuthToken.expire/1" do
    test "expires AuthToken sucessfully given an AuthToken" do
      token = insert(:auth_token, %{owner_app: Atom.to_string(@owner_app)})
      token_string = token.token

      # Ensure token is usable.
      assert AuthToken.authenticate(token_string, @owner_app)
      AuthToken.expire(token, %System{})
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end

    test "expires AuthToken successfully given the token string" do
      token = insert(:auth_token, %{owner_app: Atom.to_string(@owner_app)})
      token_string = token.token

      # Ensure token is usable.
      assert AuthToken.authenticate(token_string, @owner_app)
      AuthToken.expire(token_string, @owner_app, %System{})
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end
  end

  describe "AuthToken.expire_for_user/1" do
    test "do nothing when the given user is enabled" do
      user = insert(:user, %{enabled: true})
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, token1} = AuthToken.generate(user, @owner_app, %System{})
      token1_string = token1.token
      {:ok, token2} = AuthToken.generate(user, @owner_app, %System{})
      token2_string = token2.token

      # Ensure tokens are usable.
      assert AuthToken.authenticate(token1_string, @owner_app)
      assert AuthToken.authenticate(token2_string, @owner_app)
      AuthToken.expire_for_user(user)
      assert AuthToken.authenticate(token1_string, @owner_app)
      assert AuthToken.authenticate(token2_string, @owner_app)
    end

    test "expires all AuthToken sucessfully for the given disabled user" do
      user = insert(:user, %{enabled: false})
      account = insert(:account)
      role = insert(:role, name: "admin")
      {:ok, _} = Membership.assign(user, account, role, %System{})

      {:ok, token1} = AuthToken.generate(user, @owner_app, %System{})
      token1_string = token1.token
      {:ok, token2} = AuthToken.generate(user, @owner_app, %System{})
      token2_string = token2.token

      # Ensure tokens are usable.
      assert AuthToken.authenticate(token1_string, @owner_app)
      assert AuthToken.authenticate(token2_string, @owner_app)
      AuthToken.expire_for_user(user)
      assert AuthToken.authenticate(token1_string, @owner_app) == :token_expired
      assert AuthToken.authenticate(token2_string, @owner_app) == :token_expired
    end
  end
end
