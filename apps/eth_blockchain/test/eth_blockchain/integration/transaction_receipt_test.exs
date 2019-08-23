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

defmodule EthBlockchain.Integration.TransactionReceiptTest do
  use ExUnitFixtures
  use EthBlockchain.EthBlockchainIntegrationCase

  import Utils.Helpers.Encoding

  alias EthBlockchain.{IntegrationHelpers, TransactionReceipt}
  alias Ethereumex.HttpClient

  @moduletag :integration

  describe "get/3" do
    @tag fixtures: [:funded_hot_wallet, :alice]
    test "returns a `success` status with a receipt", %{
      funded_hot_wallet: hot_wallet,
      alice: alice
    } do
      # Note: We generate a dummy valid transaction to use for our test case
      {:ok, dummy_tx} =
        %{from: hot_wallet.address, to: alice.address, value: to_hex(100)}
        |> HttpClient.eth_send_transaction()
        |> IntegrationHelpers.transact_sync!()

      {res, status, receipt} = TransactionReceipt.get(%{tx_hash: dummy_tx["transactionHash"]})

      assert res == :ok
      assert status == :success
      assert receipt.from == hot_wallet.address
      assert receipt.to == alice.address
      assert receipt.status == 1
      assert receipt.transaction_hash == dummy_tx["transactionHash"]
    end

    @tag fixtures: [:prepare_env]
    test "returns a `not_found` status without a receipt for an invalid tx_hash" do
      data = 32 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
      fake_tx_hash = "0x" <> data
      {res, status, receipt} = TransactionReceipt.get(%{tx_hash: fake_tx_hash})

      assert res == :ok
      assert status == :not_found
      assert receipt == nil
    end
  end
end
