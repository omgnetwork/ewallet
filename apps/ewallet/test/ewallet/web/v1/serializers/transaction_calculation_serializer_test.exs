defmodule EWallet.Web.V1.TransactionCalculationSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Exchange.Calculation
  alias EWallet.Web.Date
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
        calculated_at: Date.to_iso8601(calculation.calculated_at)
      }

      assert TransactionCalculationSerializer.serialize(calculation) == expected
    end
  end
end
