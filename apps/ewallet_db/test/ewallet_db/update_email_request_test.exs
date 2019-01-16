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

defmodule EWalletDB.UpdateEmailRequestTest do
  use EWalletDB.SchemaCase, async: true
  import Ecto.Query
  import EWalletDB.Factory
  alias EWalletDB.{Repo, UpdateEmailRequest}

  defp get_request_by_uuid(uuid) do
    UpdateEmailRequest
    |> where([a], a.uuid == ^uuid)
    |> Repo.one()
  end

  describe "all_active/0" do
    test "returns only enabled requests" do
      request_1 = insert(:update_email_request, enabled: true)
      request_2 = insert(:update_email_request, enabled: false)
      request_3 = insert(:update_email_request, enabled: true)
      request_4 = insert(:update_email_request, enabled: false)
      request_5 = insert(:update_email_request, enabled: true)

      requests = UpdateEmailRequest.all_active()

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
      request = insert(:update_email_request)
      result = UpdateEmailRequest.get(request.email, request.token)

      assert result.uuid == request.uuid
    end

    test "returns nil if the request is disabled" do
      request = insert(:update_email_request, enabled: false)
      result = UpdateEmailRequest.get(request.email, request.token)

      assert result == nil
    end

    test "returns nil if email is not provided" do
      request = insert(:update_email_request)
      result = UpdateEmailRequest.get(nil, request.token)

      assert result == nil
    end

    test "returns nil if email is invalid" do
      request = insert(:update_email_request)
      result = UpdateEmailRequest.get("invalid.email@example.com", request.token)

      assert result == nil
    end

    test "returns nil if token is not provided" do
      request = insert(:update_email_request)
      result = UpdateEmailRequest.get(request.email, nil)

      assert result == nil
    end

    test "returns nil if token is invalid" do
      request = insert(:update_email_request)
      result = UpdateEmailRequest.get(request.email, "invalid_token")

      assert result == nil
    end
  end

  describe "disable_all_for/1" do
    test "disables all requests for the given user" do
      user_1 = insert(:admin)
      user_2 = insert(:admin)

      request_1 = insert(:update_email_request, user: user_1, enabled: true)
      request_2 = insert(:update_email_request, user: user_1, enabled: false)
      request_3 = insert(:update_email_request, user: user_2, enabled: true)
      request_4 = insert(:update_email_request, user: user_2, enabled: false)

      _ = UpdateEmailRequest.disable_all_for(user_1)

      assert get_request_by_uuid(request_1.uuid).enabled == false
      assert get_request_by_uuid(request_2.uuid).enabled == false
      assert get_request_by_uuid(request_3.uuid).enabled == true
      assert get_request_by_uuid(request_4.uuid).enabled == false
    end
  end

  describe "generate/2" do
    test "returns an UpdateEmailRequest" do
      user = insert(:admin)
      new_email = "new.email@example.com"

      {res, request} = UpdateEmailRequest.generate(user, new_email)

      assert res == :ok
      assert %UpdateEmailRequest{} = request
      assert request.email == new_email
      assert request.user_uuid == user.uuid
      assert String.length(request.token) == 43
    end

    test "returns an invalid changeset if the email format is invalid" do
      user = insert(:admin)
      {res, changeset} = UpdateEmailRequest.generate(user, "not an email")

      assert res == :error
      refute changeset.valid?

      assert changeset.errors == [
               email:
                 {"must be a valid email address format",
                  [validation: :valid_email_address_format]}
             ]
    end
  end
end
