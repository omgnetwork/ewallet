defmodule EWalletDB.ForgetPasswordRequestTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{ForgetPasswordRequest, Repo}

  describe "all_active/0" do
    test "returns only enabled requests" do
      request_1 = insert(:forget_password_request, enabled: true)
      request_2 = insert(:forget_password_request, enabled: false)
      request_3 = insert(:forget_password_request, enabled: true)
      request_4 = insert(:forget_password_request, enabled: false)
      request_5 = insert(:forget_password_request, enabled: true)

      requests = ForgetPasswordRequest.all_active()

      assert Enum.any?(requests, fn r -> r.uuid == request_1.uuid end)
      refute Enum.any?(requests, fn r -> r.uuid == request_2.uuid end)
      assert Enum.any?(requests, fn r -> r.uuid == request_3.uuid end)
      refute Enum.any?(requests, fn r -> r.uuid == request_4.uuid end)
      assert Enum.any?(requests, fn r -> r.uuid == request_5.uuid end)

      assert Enum.count(requests) == 3
    end
  end

  describe "get/2" do
    test "returns the request with the given email and token" do
      user = insert(:admin)
      request_1 = insert(:forget_password_request, user: user)
      request_2 = insert(:forget_password_request, user: user)
      request_3 = insert(:forget_password_request, user: user)

      result = ForgetPasswordRequest.get(user, request_2.token)

      refute result.uuid == request_1.uuid
      assert result.uuid == request_2.uuid
      refute result.uuid == request_3.uuid
    end

    test "returns nil if the request is disabled" do
      user = insert(:admin)
      request = insert(:forget_password_request, user: user, enabled: false)
      result = ForgetPasswordRequest.get(user, request.token)

      assert result == nil
    end

    test "returns nil if user is not provided" do
      user = insert(:admin)
      request = insert(:forget_password_request, user: user)
      result = ForgetPasswordRequest.get(nil, request.token)

      assert result == nil
    end

    test "returns nil if user is invalid" do
      user = insert(:admin)
      different_user = insert(:admin)
      request = insert(:forget_password_request, user: user)

      result = ForgetPasswordRequest.get(different_user, request.token)

      assert result == nil
    end

    test "returns nil if token is not provided" do
      user = insert(:admin)
      _ = insert(:forget_password_request)
      result = ForgetPasswordRequest.get(user, nil)

      assert result == nil
    end

    test "returns nil if token is invalid" do
      user = insert(:admin)
      _ = insert(:forget_password_request)
      result = ForgetPasswordRequest.get(user, "invalid_token")

      assert result == nil
    end
  end

  describe "expire/1" do
    test "expires the given request" do
      user = insert(:admin)
      request_1 = insert(:forget_password_request, user: user)
      request_2 = insert(:forget_password_request, user: user)
      request_3 = insert(:forget_password_request, user: user)

      {res, _} = ForgetPasswordRequest.expire(request_2)

      assert res == :ok
      assert ForgetPasswordRequest.get(user, request_1.token)
      refute ForgetPasswordRequest.get(user, request_2.token)
      assert ForgetPasswordRequest.get(user, request_3.token)
    end

    test "does not re-enable the request if expiring an expired request" do
      user = insert(:admin)
      request = insert(:forget_password_request, user: user, enabled: false)

      {res, _} = ForgetPasswordRequest.expire(request)

      assert res == :ok
      refute ForgetPasswordRequest.get(user, request.token)
    end
  end

  describe "expire_as_used/1" do
    test "expires and sets used_at on the given request" do
      user = insert(:admin)
      request = insert(:forget_password_request, user: user)

      {res, _} = ForgetPasswordRequest.expire_as_used(request)

      assert res == :ok
      assert ForgetPasswordRequest |> Repo.get(request.uuid) |> Map.get(:used_at) != nil
    end
  end

  describe "generate/2" do
    test "returns an ForgetPasswordRequest" do
      user = insert(:admin)
      {res, request} = ForgetPasswordRequest.generate(user)

      assert res == :ok

      assert %ForgetPasswordRequest{} = request
      assert request.enabled == true
      assert request.user_uuid == user.uuid
      assert request.expires_at != nil
      assert request.token |> String.length() == 43
    end
  end
end
