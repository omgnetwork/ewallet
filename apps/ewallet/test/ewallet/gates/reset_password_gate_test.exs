defmodule EWallet.ResetPasswordGateTest do
  use EWallet.DBCase, async: true
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

    test "disables all pending requests" do
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      request_1 = insert(:forget_password_request, user_uuid: admin_1.uuid)
      request_2 = insert(:forget_password_request, user_uuid: admin_2.uuid)
      request_3 = insert(:forget_password_request, user_uuid: admin_3.uuid)

      assert ForgetPasswordRequest.get(admin_1, request_1.token).enabled
      assert ForgetPasswordRequest.get(admin_2, request_2.token).enabled
      assert ForgetPasswordRequest.get(admin_3, request_3.token).enabled

      {:ok, _request} = ResetPasswordGate.request(admin_2.email)

      assert ForgetPasswordRequest.get(admin_1, request_1.token)
      refute ForgetPasswordRequest.get(admin_2, request_2.token)
      assert ForgetPasswordRequest.get(admin_3, request_3.token)
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
