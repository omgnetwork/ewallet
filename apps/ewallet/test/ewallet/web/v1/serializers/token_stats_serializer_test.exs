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

defmodule EWallet.Web.V1.TokenStatsSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.{TokenSerializer, TokenStatsSerializer}

  describe "serialize/1" do
    test "serializes into a token_stats object" do
      stats = %{
        token: insert(:token),
        total_supply: 1_234_567
      }

      expected = %{
        object: "token_stats",
        token_id: stats.token.id,
        token: TokenSerializer.serialize(stats.token),
        total_supply: stats.total_supply
      }

      assert TokenStatsSerializer.serialize(stats) == expected
    end

    test "serializes nil to nil" do
      assert TokenStatsSerializer.serialize(nil) == nil
    end
  end
end
