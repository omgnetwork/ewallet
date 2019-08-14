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

defmodule EWallet.BlockchainDepositWalletGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.BlockchainDepositWalletGate

  describe "get_or_generate/2" do
    test "generates a deposit wallet if it is not yet generated for the given wallet"
    test "returns the existing deposit wallet if it is already generated for the given wallet"
    test "returns :hd_wallet_not_found error if the primary HD wallet is missing"
  end
end
