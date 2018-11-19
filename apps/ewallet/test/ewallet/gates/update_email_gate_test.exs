defmodule EWallet.UpdateEmailGateTest do
  use EWallet.DBCase, async: true
  alias EWallet.UpdateEmailGate
  alias EWalletDB.{UpdateEmailRequest, User}

  describe "update/3" do
    test "returns {:ok, request} with the user's email unchanged" do
      admin = insert(:admin, email: "test.update.email.gate@example.com")

      {res, request} =
        UpdateEmailGate.update(admin, "test.update.email.gate2@example.com")

      assert res == :ok
      assert %UpdateEmailRequest{} = request
      assert User.get(admin.id).email == admin.email
    end

    test "disables all pending update requests" do
      admin = insert(:admin)

      request_1 = insert(:update_email_request, user_uuid: admin.uuid)
      request_2 = insert(:update_email_request)
      request_3 = insert(:update_email_request, user_uuid: admin.uuid)

      assert UpdateEmailRequest.get(request_1.email, request_1.token).enabled
      assert UpdateEmailRequest.get(request_2.email, request_2.token).enabled
      assert UpdateEmailRequest.get(request_3.email, request_3.token).enabled

      {:ok, _request} =
        UpdateEmailGate.update(admin, "test.update.email.gate2@example.com")

      assert UpdateEmailRequest.get(request_1.email, request_1.token) == nil
      assert UpdateEmailRequest.get(request_2.email, request_2.token) != nil
      assert UpdateEmailRequest.get(request_3.email, request_3.token) == nil
    end

    test "returns an error if there is already a user with the associated email" do
      admin = insert(:admin)
      another_admin = insert(:admin)

      {res, code} =
        UpdateEmailGate.update(admin, another_admin.email)

      assert res == :error
      assert code == :email_already_exists
    end
  end

  describe "verify/2" do
    test "returns {:ok, user} if verification is successful" do
      admin = insert(:admin)
      request = insert(:update_email_request, user_uuid: admin.uuid)

      {res, user} = UpdateEmailGate.verify(request.email, request.token)

      assert res == :ok
      assert user.uuid == request.user_uuid
    end

    test "updates the email if verification is successful" do
      admin = insert(:admin, email: "original@example.com")
      request = insert(:update_email_request, email: "new@example.com", user_uuid: admin.uuid)

      assert User.get(admin.id).email == "original@example.com"

      {res, user} = UpdateEmailGate.verify(request.email, request.token)

      assert res == :ok
      assert user.uuid == request.user_uuid
      assert User.get(admin.id).email == "new@example.com"
    end

    test "disables the token after use" do
      admin = insert(:admin)
      request = insert(:update_email_request, user_uuid: admin.uuid)

      {:ok, _} = UpdateEmailGate.verify(request.email, request.token)

      assert UpdateEmailRequest.get(request.email, request.token) == nil
    end

    test "prevents updating to an email address that's already used" do
      admin = insert(:admin)
      another_admin = insert(:admin)
      request = insert(:update_email_request, user_uuid: admin.uuid, email: another_admin.email)

      {res, changeset} = UpdateEmailGate.verify(request.email, request.token)

      assert res == :error
      assert changeset.valid? == false
      assert changeset.errors == [email: {"has already been taken", []}]
    end

    test "returns :invalid_email_update_token error if the email does not match the token" do
      admin = insert(:admin)
      request = insert(:update_email_request, user_uuid: admin.uuid)

      {res, code} = UpdateEmailGate.verify("incorrect_email", request.token)

      assert res == :error
      assert code == :invalid_email_update_token
    end

    test "returns :invalid_email_update_token error if the token could not be found" do
      admin = insert(:admin)
      request = insert(:update_email_request, user_uuid: admin.uuid)

      {res, code} = UpdateEmailGate.verify(request.email, "invalid_token")

      assert res == :error
      assert code == :invalid_email_update_token
    end
  end
end
