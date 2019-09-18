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

defmodule EthBlockchain.AdapterTest do
  use EthBlockchain.EthBlockchainCase
  alias EthBlockchain.{Adapter, TransactionListener}

  describe "subscribe/5" do
    test "returns :ok" do
      assert Adapter.subscribe(:transaction, "0x123456789", false, self()) == :ok
    end
  end

  describe "unsubscribe/3" do
    test "unsubscribes the given subscriber from the registry for the given transaction hash" do
      :ok = Adapter.subscribe(:transaction, "0x123456789", false, self())
      assert Adapter.unsubscribe(:transaction, "0x123456789", self()) == :ok
    end
  end

  describe "lookup_listener/1" do
    test "returns the list of subscribers for the given transaction hash" do
      :ok = Adapter.subscribe(:transaction, "0x123456789", false, self())
      {res, listener} = Adapter.lookup_listener("0x123456789")

      assert res == :ok
      assert listener.listener == TransactionListener
      assert is_pid(listener.pid)
    end
  end
end
