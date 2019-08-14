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

defmodule EthBlockchain.NonceTest do
  use EthBlockchain.EthBlockchainCase
  alias EthBlockchain.{DumbAdapter, Nonce}

  describe "start_link/1" do
    test "starts a new nonce handler" do
      assert {:ok, pid} = Nonce.start_link(name: :test_nonce)
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits with empty map" do
      assert Nonce.init(:ok) == {:ok, %{}}
    end
  end

  describe "next_nonce/4" do
    test "returns the current transaction count if not in state" do
      assert {:ok, pid} = Nonce.start_link(name: :test_nonce)

      assert {:ok, 100} =
               Nonce.next_nonce(DumbAdapter.high_transaction_count_address(), nil, nil, pid)

      assert GenServer.stop(pid) == :ok
    end

    test "returns the next nonce to use if in state" do
      assert {:ok, pid} = Nonce.start_link(name: :test_nonce)

      assert {:ok, 100} =
               Nonce.next_nonce(DumbAdapter.high_transaction_count_address(), nil, nil, pid)

      assert {:ok, 101} =
               Nonce.next_nonce(DumbAdapter.high_transaction_count_address(), nil, nil, pid)

      assert GenServer.stop(pid) == :ok
    end
  end

  describe "force_refresh/4" do
    test "refresh the nonce from the transaction count" do
      address = DumbAdapter.high_transaction_count_address()
      assert {:ok, pid} = Nonce.start_link(name: :test_nonce)
      assert {:ok, 100} = Nonce.next_nonce(address, nil, nil, pid)
      assert {:ok, 100} = Nonce.force_refresh(address, nil, nil, pid)
      assert {:ok, 100} = Nonce.next_nonce(address, nil, nil, pid)

      assert GenServer.stop(pid) == :ok
    end
  end
end
