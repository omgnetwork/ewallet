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

defmodule EWallet.Web.V1.BalanceSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{BalanceSerializer, TokenSerializer}

  describe "serialize/1" do
    test "serializes a balance into the correct response format" do
      balance = %{
        token: insert(:token),
        amount: 1_000_000
      }

      expected = %{
        object: "balance",
        token: TokenSerializer.serialize(balance.token),
        amount: balance.amount
      }

      assert BalanceSerializer.serialize(balance) == expected
    end

    test "serializes to nil if the balance is not loaded" do
      assert BalanceSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes nil to nil " do
      assert BalanceSerializer.serialize(nil) == nil
    end
  end
end
