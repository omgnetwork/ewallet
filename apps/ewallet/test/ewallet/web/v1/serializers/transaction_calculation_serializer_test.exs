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

defmodule EWallet.Web.V1.TransactionCalculationSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Exchange.Calculation
  alias Utils.Helpers.DateFormatter
  alias EWallet.Web.V1.{ExchangePairSerializer, TransactionCalculationSerializer}

  describe "serialize/1" do
    test "serializes into correct V1 transaction calculation format" do
      pair = insert(:exchange_pair)

      calculation = %Calculation{
        from_amount: 1000,
        from_token: pair.from_token,
        to_amount: 2000,
        to_token: pair.to_token,
        actual_rate: pair.rate,
        pair: pair,
        calculated_at: NaiveDateTime.utc_now()
      }

      expected = %{
        object: "transaction_calculation",
        from_amount: calculation.from_amount,
        from_token_id: calculation.from_token.id,
        to_amount: calculation.to_amount,
        to_token_id: calculation.to_token.id,
        actual_rate: calculation.actual_rate,
        exchange_pair: ExchangePairSerializer.serialize(calculation.pair),
        calculated_at: DateFormatter.to_iso8601(calculation.calculated_at)
      }

      assert TransactionCalculationSerializer.serialize(calculation) == expected
    end
  end
end
