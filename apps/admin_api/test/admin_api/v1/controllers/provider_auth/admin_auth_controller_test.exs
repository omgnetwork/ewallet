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

defmodule AdminAPI.V1.ProviderAuth.AdminAuthControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/auth_token.switch_account" do
    test "gets access_key:unauthorized back" do
      account = insert(:account)

      # User belongs to the master account and has access to the sub account
      # just created
      response =
        provider_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end

  describe "/me.logout" do
    test "gets access_key:unauthorized back" do
      response = provider_request("/me.logout")
      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end
end
