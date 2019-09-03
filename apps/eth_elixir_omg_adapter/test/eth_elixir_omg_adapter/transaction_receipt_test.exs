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

defmodule EthElixirOmgAdapter.TransactionReceiptTest do
  use EthElixirOmgAdapter.EthElixirOmgAdapterCase, async: true

  alias EthElixirOmgAdapter.{TransactionReceipt, ResponseBody}

  describe "get/1" do
    test "get a valid transaction" do
      {res, code, parsed_tx} = TransactionReceipt.get("valid")
      assert res == :ok
      assert code == :success
      success_body = ResponseBody.transaction_get_success()["data"]

      assert parsed_tx ==
               %TransactionReceipt{
                 eth_block: %{
                   number: success_body["block"]["eth_height"],
                   hash: success_body["block"]["hash"],
                   timestamp: success_body["block"]["timestamp"]
                 },
                 cc_block_number: success_body["block"]["blknum"],
                 inputs: [
                   %{
                     amount: Enum.at(success_body["inputs"], 0)["amount"],
                     block_number: Enum.at(success_body["inputs"], 0)["blknum"],
                     currency: Enum.at(success_body["inputs"], 0)["currency"],
                     oindex: Enum.at(success_body["inputs"], 0)["oindex"],
                     owner: Enum.at(success_body["inputs"], 0)["owner"],
                     transaction_index: Enum.at(success_body["inputs"], 0)["txindex"],
                     utxo_position: Enum.at(success_body["inputs"], 0)["utxo_pos"]
                   }
                 ],
                 outputs: [
                   %{
                     amount: Enum.at(success_body["outputs"], 0)["amount"],
                     block_number: Enum.at(success_body["outputs"], 0)["blknum"],
                     currency: Enum.at(success_body["outputs"], 0)["currency"],
                     oindex: Enum.at(success_body["outputs"], 0)["oindex"],
                     owner: Enum.at(success_body["outputs"], 0)["owner"],
                     transaction_index: Enum.at(success_body["outputs"], 0)["txindex"],
                     utxo_position: Enum.at(success_body["outputs"], 0)["utxo_pos"]
                   },
                   %{
                     amount: Enum.at(success_body["outputs"], 1)["amount"],
                     block_number: Enum.at(success_body["outputs"], 1)["blknum"],
                     currency: Enum.at(success_body["outputs"], 1)["currency"],
                     oindex: Enum.at(success_body["outputs"], 1)["oindex"],
                     owner: Enum.at(success_body["outputs"], 1)["owner"],
                     transaction_index: Enum.at(success_body["outputs"], 1)["txindex"],
                     utxo_position: Enum.at(success_body["outputs"], 1)["utxo_pos"]
                   }
                 ],
                 metadata: success_body["metadata"],
                 transaction_bytes: success_body["txbytes"],
                 transaction_hash: success_body["txhash"],
                 transaction_index: success_body["txindex"]
               }
    end

    test "get a not found transaction" do
      {res, code} = TransactionReceipt.get("invalid")
      assert res == :ok
      assert code == :not_found
    end
  end
end
