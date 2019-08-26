# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.UserGateTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWallet.UserGate
  alias EWalletDB.{Membership, Role}

  setup do
    original_email = Application.get_env(:admin_api, :sender_email)
    :ok = Application.put_env(:admin_api, :sender_email, "admin@example.com")
    on_exit(fn -> Application.put_env(:admin_api, :sender_email, original_email) end)

    redirect_url = Application.get_env(:ewallet, :base_url) <> "/some_redirect_url"

    {:ok, %{redirect_url: redirect_url}}
  end

  describe "get_user_or_email/1" do
    test "returns the user by the given user_id" do
      inserted = insert(:user)
      attrs = %{"user_id" => inserted.id}

      {res, user} = UserGate.get_user_or_email(attrs)

      assert res == :ok
      assert user.uuid == inserted.uuid
    end

    test "returns the user by the given email" do
      inserted = insert(:user, email: "some_user@example.com")
      attrs = %{"email" => inserted.email}

      {res, user} = UserGate.get_user_or_email(attrs)

      assert res == :ok
      assert user.uuid == inserted.uuid
    end

    test "returns :unauthorized error when the user_id could not be found" do
      attrs = %{"user_id" => "nonexistent_id"}
      assert UserGate.get_user_or_email(attrs) == {:error, :unauthorized}
    end

    test "returns {:ok, email} when the user's email could not be found" do
      email = "nonexistent@example.com"
      attrs = %{"email" => email}
      assert UserGate.get_user_or_email(attrs) == {:ok, email}
    end

    test "returns :invalid_email error when the email is given as nil" do
      attrs = %{"email" => nil}
      assert UserGate.get_user_or_email(attrs) == {:error, :invalid_email}
    end
  end

  describe "validate_redirect_url/1" do
    test "returns {:ok, url} when the given redirect_url is allowed" do
      url = Application.get_env(:ewallet, :base_url) <> "/some_redirect_url"
      assert UserGate.validate_redirect_url(url) == {:ok, url}
    end

    test "returns {:error, :prohibited_url, _} when the given redirect_url is not allowed" do
      url = "http://some-suspicious-url.com" <> "/some_redirect_url"

      assert UserGate.validate_redirect_url(url) ==
               {:error, :prohibited_url, param_name: "redirect_url", url: url}
    end
  end

  describe "invite_global_user/2" do
    test "returns {:ok, invite} when the given email is a valid format", context do
      attrs = %{"email" => "the.other.admin@example.com", "originator" => %System{}}
      {res, invite} = UserGate.invite_global_user(attrs, context.redirect_url)

      assert res == :ok
      assert invite.user.email == attrs["email"]
    end

    test "returns {:error, :invalid_email} when the given email is not valid format", context do
      attrs = %{"email" => "not_an_email", "originator" => %System{}}
      assert UserGate.invite_global_user(attrs, context.redirect_url) == {:error, :invalid_email}
    end
  end

  describe "assign_or_invite/5" do
    test "returns {:ok, invite} when the given email is a valid format", context do
      email = "the.other.admin@example.com"
      account = insert(:account)
      role = Role.get_by(name: "admin")

      {res, invite} =
        UserGate.assign_or_invite(email, account, role, context.redirect_url, %System{})

      assert res == :ok
      assert invite.user.email == email
    end

    test "returns {:error, :invalid_email} when the given email is not valid format", context do
      email = "not_an_email"
      account = insert(:account)
      role = Role.get_by(name: "admin")

      assert UserGate.assign_or_invite(email, account, role, context.redirect_url, %System{}) ==
               {:error, :invalid_email}
    end

    test "returns {:ok, invite} when the given user's status is pending_confirmation", context do
      email = "the.other.admin@example.com"
      account = insert(:account)
      role = Role.get_by(name: "admin")

      {:ok, invite} =
        UserGate.assign_or_invite(email, account, role, context.redirect_url, %System{})

      {res, re_invite} =
        UserGate.assign_or_invite(invite.user, account, role, context.redirect_url, %System{})

      assert res == :ok
      assert re_invite.user_uuid == invite.user_uuid
      assert re_invite.uuid == invite.uuid
    end

    test "returns {:ok, membership} when the user's status is active", context do
      user = insert(:user)
      account = insert(:account)
      role = Role.get_by(name: "admin")

      {res, membership} =
        UserGate.assign_or_invite(user, account, role, context.redirect_url, %System{})

      assert res == :ok
      assert %Membership{} = membership
    end
  end
end
