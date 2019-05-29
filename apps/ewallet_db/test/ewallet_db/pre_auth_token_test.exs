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
