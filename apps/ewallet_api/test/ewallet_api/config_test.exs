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

defmodule EWalletAPI.ConfigTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletConfig.Config
  alias ActivityLogger.System

  describe "ewallet_api.enable_standalone" do
    test "allows /user.signup when configured to true", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: true,
            originator: %System{}
          },
          meta[:config_pid]
        )

      response = client_request("/user.signup")

      # Asserting `user:invalid_email` is good enough to verify
      # that the endpoint is accessible and being processed.
      assert response["data"]["code"] == "user:invalid_email"
    end

    test "prohibits /user.signup when configured to false", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: false,
            originator: %System{}
          },
          meta[:config_pid]
        )

      response = client_request("/user.signup")

      assert response["data"]["code"] == "client:endpoint_not_found"
    end
  end
end
