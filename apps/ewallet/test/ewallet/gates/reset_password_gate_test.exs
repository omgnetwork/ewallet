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

defmodule EWallet.ResetPasswordGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.ResetPasswordGate
  alias EWalletDB.{ForgetPasswordRequest, User}

  describe "request/1" do
    test "returns {:ok, request} with the user's password unchanged" do
      admin = insert(:admin)

      {res, request} = ResetPasswordGate.request(admin.email)

      assert res == :ok
      assert %ForgetPasswordRequest{} = request
      assert User.get(admin.id).password_hash == admin.password_hash
    end

    test "allows multiple active requests" do
      admin = insert(:admin)

      request_1 = insert(:forget_password_request, user_uuid: admin.uuid)
      request_2 = insert(:forget_password_request, user_uuid: admin.uuid)

      assert ForgetPasswordRequest.get(admin, request_1.token).enabled
      assert ForgetPasswordRequest.get(admin, request_2.token).enabled

      {:ok, request_3} = ResetPasswordGate.request(admin.email)

      assert ForgetPasswordRequest.get(admin, request_1.token)
      assert ForgetPasswordRequest.get(admin, request_2.token)
      assert ForgetPasswordRequest.get(admin, request_3.token)
    end

    test "returns :user_email_not_found if the email could not be found" do
      {res, error} = ResetPasswordGate.request("some.unknown@example.com")

      assert res == :error
      assert error == :user_email_not_found
    end
  end

  describe "update/4" do
    test "returns {:ok, user} if the password update is successful" do
      admin = insert(:admin)
      request = insert(:forget_password_request, user_uuid: admin.uuid)
      password = "new.password"

      {res, user} = ResetPasswordGate.update(admin.email, request.token, password, password)

      assert res == :ok
      assert user.uuid == request.user_uuid
    end

    test "updates the password if the verification is successful" do
      admin = insert(:admin)
      request = insert(:forget_password_request, user_uuid: admin.uuid)
      password = "new.password"

      assert User.get(admin.id).password_hash == admin.password_hash

      {res, updated} = ResetPasswordGate.update(admin.email, request.token, password, password)

      assert res == :ok
      assert updated.uuid == request.user_uuid
      assert updated.password_hash != admin.password_hash
    end

    test "disables the token after use" do
      admin = insert(:admin)
      request = insert(:forget_password_request, user_uuid: admin.uuid)
      password = "new.password"

      assert ForgetPasswordRequest.get(admin, request.token) != nil

      {:ok, _} = ResetPasswordGate.update(admin.email, request.token, password, password)

      assert ForgetPasswordRequest.get(admin, request.token) == nil
    end

    test "allows remaining requests to be used" do
      admin = insert(:admin)
      request_1 = insert(:forget_password_request, user_uuid: admin.uuid)
      request_2 = insert(:forget_password_request, user_uuid: admin.uuid)
      request_3 = insert(:forget_password_request, user_uuid: admin.uuid)

      {:ok, _} = ResetPasswordGate.update(admin.email, request_1.token, "newpass1", "newpass1")
      {:ok, _} = ResetPasswordGate.update(admin.email, request_2.token, "newpass2", "newpass2")
      {:ok, _} = ResetPasswordGate.update(admin.email, request_3.token, "newpass3", "newpass3")
    end

    test "returns :invalid_reset_token error if the request is already expired" do
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      expires_at = NaiveDateTime.utc_now() |> NaiveDateTime.add(-10)
      request = insert(:forget_password_request, user_uuid: admin_1.uuid, expires_at: expires_at)
      password = "new.password"

      {res, code} = ResetPasswordGate.update(admin_2.email, request.token, password, password)

      assert res == :error
      assert code == :invalid_reset_token
    end

    test "returns :invalid_reset_token error if the email does not match the token" do
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      request = insert(:forget_password_request, user_uuid: admin_1.uuid)
      password = "new.password"

      {res, code} = ResetPasswordGate.update(admin_2.email, request.token, password, password)

      assert res == :error
      assert code == :invalid_reset_token
    end

    test "returns :invalid_reset_token error if the token could not be found" do
      admin = insert(:admin)
      _request = insert(:forget_password_request, user_uuid: admin.uuid)
      password = "new.password"

      {res, code} = ResetPasswordGate.update(admin.email, "invalid_token", password, password)

      assert res == :error
      assert code == :invalid_reset_token
    end
  end
end
