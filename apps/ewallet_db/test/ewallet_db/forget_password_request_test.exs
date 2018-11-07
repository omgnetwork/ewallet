defmodule EWalletDB.ForgetPasswordRequestTest do
  use EWalletDB.SchemaCase
  import Ecto.Query
  alias EWalletDB.{Repo, ForgetPasswordRequest}

  defp get_request_by_uuid(uuid) do
    ForgetPasswordRequest
    |> where([a], a.uuid == ^uuid)
    |> Repo.one()
  end

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
      request = insert(:forget_password_request, user: user)
      result = ForgetPasswordRequest.get(user, request.token)

      assert result.uuid == request.uuid
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

  describe "disable_all_for/1" do
    test "disables all requests for the given user" do
      user_1 = insert(:admin)
      user_2 = insert(:admin)

      request_1 = insert(:forget_password_request, user: user_1, enabled: true)
      request_2 = insert(:forget_password_request, user: user_1, enabled: false)
      request_3 = insert(:forget_password_request, user: user_2, enabled: true)
      request_4 = insert(:forget_password_request, user: user_2, enabled: false)

      _ = ForgetPasswordRequest.disable_all_for(user_1)

      assert get_request_by_uuid(request_1.uuid).enabled == false
      assert get_request_by_uuid(request_2.uuid).enabled == false
      assert get_request_by_uuid(request_3.uuid).enabled == true
      assert get_request_by_uuid(request_4.uuid).enabled == false
    end
  end

  describe "generate/2" do
    test "returns an ForgetPasswordRequest" do
      user = insert(:admin)
      request = ForgetPasswordRequest.generate(user)

      assert %ForgetPasswordRequest{} = request
      assert request.user_uuid == user.uuid
      assert String.length(request.token) == 43
    end
  end
end
