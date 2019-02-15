# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule EWallet.TokenGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.{GethSimulator, TokenGate}
  alias EWalletDB.Token

  describe "import/1" do
    test "imports the token successfully" do
      GethSimulator.start()

      {res, token} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :ok
      assert %Token{} = token
    end
  end
end
