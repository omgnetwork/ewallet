# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.StandalonePlugTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletAPI.V1.StandalonePlug
  alias EWalletConfig.Config
  alias ActivityLogger.System

  describe "call/2" do
    test "does not halt if ewallet_api.enable_standalone is true", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: true,
            originator: %System{}
          },
          meta[:config_pid]
        )

      conn = StandalonePlug.call(build_conn(), [])
      refute conn.halted
    end

    test "halts if ewallet_api.enable_standalone is false", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: false,
            originator: %System{}
          },
          meta[:config_pid]
        )

      conn = StandalonePlug.call(build_conn(), [])
      assert conn.halted
    end
  end
end
