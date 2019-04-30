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

defmodule EWallet.UserAuthTokenTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWallet.UserAuthenticator
  alias EWalletDB.{AuthToken, PreAuthToken}

  describe "authenticate" do
    test "return user if the given user has enabled 2FA and the given token existed" do
      user = insert(:user, %{enabled_2fa_at: ~N[2000-02-02 20:02:02], originator: nil})
      {:ok, auth_token} = AuthToken.generate(user, :admin_api, %System{})

      assert UserAuthenticator.authenticate(user, auth_token.token, :admin_api) == user
    end

    test "return user if the given user does not enable 2FA and the given token existed" do
      user = insert(:user, %{enabled_2fa_at: nil, originator: nil})
      {:ok, auth_token} = AuthToken.generate(user, :admin_api, %System{})

      assert UserAuthenticator.authenticate(user, auth_token.token, :admin_api) == user
    end

    test "return PreAuthToken if the given user has enabled 2FA and the given token existed" do
      user = insert(:user, %{enabled_2fa_at: ~N[2000-02-02 20:02:02], originator: nil})
      {:ok, auth_token} = PreAuthToken.generate(user, :admin_api, %System{})

      assert pre_auth_token = UserAuthenticator.authenticate(user, auth_token.token, :admin_api)
      assert pre_auth_token.token == auth_token.token
    end

    test "return false if the given user has enabled 2FA but the given token doesn't exist" do
      user = insert(:user, %{enabled_2fa_at: ~N[2000-02-02 20:02:02], originator: nil})

      assert UserAuthenticator.authenticate(user, "1234", :admin_api) == false
    end

    test "return false if the given token doesn't exist" do
      user = insert(:user, %{originator: nil})

      assert UserAuthenticator.authenticate(user, "1234", :admin_api) == false
    end

    test "return false if the given user is nil" do
      user = insert(:user)

      assert UserAuthenticator.authenticate(user, nil, :admin_api) == false
    end

    test "return false if the given token is nil" do
      assert UserAuthenticator.authenticate(nil, "1234", :admin_api) == false
    end
  end

  describe "generate" do
    test "return {:error, :invalid_parameter} if the given user is nil" do
      assert UserAuthenticator.generate(nil, :admin_api, %System{}) == {:error, :invalid_parameter}
    end

    test "return {:ok, PreAuthToken} if the given user has enabled two-factor authentication" do
      user = insert(:user, %{enabled_2fa_at: ~N[2000-02-02 20:02:02]})

      assert {:ok, %PreAuthToken{}} = UserAuthenticator.generate(user, :admin_api, %System{})
    end

    test "return {:ok, AuthToken} if the given user has not enabled two-factor authentication" do
      user = insert(:user, %{enabled_2fa_at: nil})

      assert {:ok, %AuthToken{}} = UserAuthenticator.generate(user, :admin_api, %System{})
    end
  end
end
