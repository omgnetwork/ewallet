defmodule EWallet.UpdateEmailGateTest do
  use EWallet.DBCase, async: true
  use Bamboo.Test
  alias Bamboo.Email
  alias EWallet.UpdateEmailGate
  alias EWalletDB.{Repo, UpdateEmailRequest, User}
  alias AdminAPI.UpdateEmailAddressEmail

  @redirect_url "http://localhost:4000/update_email?email={email}&token={token}"

  describe "update/3" do
    test "returns {:ok, user, email} with the user's email unchanged" do
      admin = insert(:admin, email: "test.update.email.gate@example.com")

      {res, user, email} =
        UpdateEmailGate.update(admin, "test.update.email.gate2@example.com", @redirect_url)

      assert res == :ok
      assert user.id == admin.id
      assert %Email{} = email
    end

    test "disables all pending update requests" do
      admin = insert(:admin)

      request_1 = insert(:update_email_request, user_uuid: admin.uuid)
      request_2 = insert(:update_email_request)
      request_3 = insert(:update_email_request, user_uuid: admin.uuid)

      assert UpdateEmailRequest.get(request_1.email, request_1.token).enabled
      assert UpdateEmailRequest.get(request_2.email, request_2.token).enabled
      assert UpdateEmailRequest.get(request_3.email, request_3.token).enabled

      {:ok, _user, _email} =
        UpdateEmailGate.update(admin, "test.update.email.gate2@example.com", @redirect_url)

      assert UpdateEmailRequest.get(request_1.email, request_1.token) == nil
      assert UpdateEmailRequest.get(request_2.email, request_2.token) != nil
      assert UpdateEmailRequest.get(request_3.email, request_3.token) == nil
    end

    test "sends a verification email" do
      admin = insert(:admin)

      {:ok, _, _} =
        UpdateEmailGate.update(admin, "test.sends.verification@example.com", @redirect_url)

      request =
        UpdateEmailRequest
        |> Repo.get_by(user_uuid: admin.uuid)
        |> Repo.preload(:user)

      assert_delivered_email(UpdateEmailAddressEmail.create(request, @redirect_url))
    end

    test "returns client:invalid_parameter error if the redirect_url is not allowed" do
      admin = insert(:admin)
      redirect_url = "http://unknown-url.com/update_email?email={email}&token={token}"

      {res, code, meta} =
        UpdateEmailGate.update(admin, "test.redirect_url.not.provided@example.com", redirect_url)

        assert res == :error
        assert code == :prohibited_url
        assert meta == [param_name: "redirect_url", url: redirect_url]
    end

    test "returns an error if there is already a user with the associated email" do
      admin = insert(:admin)
      another_admin = insert(:admin)

      {res, code} =
        UpdateEmailGate.update(admin, another_admin.email, @redirect_url)

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
