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

defmodule EWallet.Bouncer.ExchangePairTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{ExchangePairTarget, DispatchConfig}

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the exchange pair" do
      exchange_pair = insert(:exchange_pair)
      res = ExchangePairTarget.get_owner_uuids(exchange_pair)
      assert res == []
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert ExchangePairTarget.get_target_types() == [:exchange_pairs]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given exchange pair" do
      assert ExchangePairTarget.get_target_type(ExchangePair) == :exchange_pairs
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the exchange pair" do
      exchange_pair = insert(:exchange_pair)
      assert ExchangePairTarget.get_target_accounts(exchange_pair, DispatchConfig) == []
    end
  end
end
