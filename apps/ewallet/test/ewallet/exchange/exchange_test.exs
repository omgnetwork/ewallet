defmodule EWallet.ExchangeTest do
  use EWallet.DBCase
  alias EWallet.Exchange

  setup do
    %{
      omg: insert(:token),
      eth: insert(:token)
    }
  end

  describe "get_rate/2" do
    test "returns the rate and exchange pair", context do
      inserted_pair =
        insert(
          :exchange_pair,
          from_token: context.omg,
          to_token: context.eth,
          rate: 100.0,
          reversible: false
        )

      {res, rate, pair} = Exchange.get_rate(context.omg, context.eth)

      assert res == :ok
      assert rate == 100.0
      assert pair.uuid == inserted_pair.uuid
    end

    test "returns the direct rate and pair if both direct and reversed rates are found",
         context do
      direct_pair =
        insert(
          :exchange_pair,
          from_token: context.omg,
          to_token: context.eth,
          rate: 100.0,
          reversible: false
        )

      _reversed_pair =
        insert(
          :exchange_pair,
          from_token: context.eth,
          to_token: context.omg,
          rate: 0.0000009,
          reversible: true
        )

      {res, rate, pair} = Exchange.get_rate(context.omg, context.eth)

      assert res == :ok
      assert rate == 100.0
      assert pair.uuid == direct_pair.uuid
    end

    test "returns the reversed rate and exchange pair", context do
      inserted_pair =
        insert(
          :exchange_pair,
          from_token: context.omg,
          to_token: context.eth,
          rate: 0.1,
          reversible: true
        )

      {res, rate, pair} = Exchange.get_rate(context.eth, context.omg)

      assert res == :ok
      # Asserting `1 / rate` because we're using a reversed pair
      assert rate == 1 / inserted_pair.rate
      assert pair.uuid == inserted_pair.uuid
    end

    test "returns {:error, :exchange_pair_not_found} if the exchange pair is not found",
         context do
      {res, code} = Exchange.get_rate(context.omg, context.eth)

      assert res == :error
      assert code == :exchange_pair_not_found
    end
  end

  describe "get_rate/2 for tokens with diiferent subunit_to_unit values" do
    test "returns the adjusted subunit rate" do
      omg = insert(:token, subunit_to_unit: 1_000)
      eth = insert(:token, subunit_to_unit: 1_000_000)

      inserted_pair =
        insert(
          :exchange_pair,
          from_token: omg,
          to_token: eth,
          rate: 5.0,
          reversible: false
        )

      {res, rate, pair} = Exchange.get_rate(omg, eth)

      assert res == :ok
      assert rate == 5.0 * (1_000_000 / 1_000)
      assert pair.uuid == inserted_pair.uuid
    end

    test "returns the reversed and adjusted subunit rate" do
      omg = insert(:token, subunit_to_unit: 1_000)
      eth = insert(:token, subunit_to_unit: 1_000_000)

      inserted_pair =
        insert(
          :exchange_pair,
          from_token: eth,
          to_token: omg,
          rate: 5.0,
          reversible: true
        )

      {res, rate, pair} = Exchange.get_rate(omg, eth)

      assert res == :ok
      assert rate == 1 / 5.0 * (1_000_000 / 1_000)
      assert pair.uuid == inserted_pair.uuid
    end
  end

  describe "validate/4 with the same token" do
    test "returns {:ok, calculation} if amounts are the same", context do
      {result, calculation} = Exchange.validate(10, context.omg, 10, context.omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == context.omg.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == context.omg.uuid
      assert calculation.actual_rate == 1
      assert calculation.pair == nil
    end

    test "returns a {:error, :exchange_invalid_rate} if amounts are different", context do
      {result, code} = Exchange.validate(10, context.omg, 100, context.omg)

      assert result == :error
      assert code == :exchange_invalid_rate
    end
  end

  describe "validate/4 with cross tokens" do
    test "returns {:ok, calculation} if the amounts match the rate", context do
      pair =
        insert(
          :exchange_pair,
          from_token: context.eth,
          to_token: context.omg,
          rate: 10.0,
          reversible: false
        )

      {result, calculation} = Exchange.validate(10, context.eth, 100, context.omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == context.eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == context.omg.uuid
      assert calculation.actual_rate == pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns an :exchange_invalid_rate error if amounts do not match the rate", context do
      _ =
        insert(
          :exchange_pair,
          from_token: context.eth,
          to_token: context.omg,
          rate: 10.0,
          reversible: false
        )

      # Using false rate of 100.0
      {result, code} = Exchange.validate(10, context.eth, 1000, context.omg)

      assert result == :error
      assert code == :exchange_invalid_rate
    end
  end

  describe "calculate/4 with a nil `from_amount`" do
    test "returns the calculation using a direct pair", context do
      pair =
        insert(
          :exchange_pair,
          from_token: context.eth,
          to_token: context.omg,
          rate: 0.1,
          reversible: false
        )

      {result, calculation} = Exchange.calculate(nil, context.eth, 10, context.omg)

      assert result == :ok
      assert calculation.from_amount == 100
      assert calculation.from_token.uuid == context.eth.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == context.omg.uuid
      assert calculation.actual_rate == pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns the calculation using a reversed pair", context do
      pair =
        insert(
          :exchange_pair,
          from_token: context.omg,
          to_token: context.eth,
          rate: 10.0,
          reversible: true
        )

      {result, calculation} = Exchange.calculate(nil, context.eth, 10, context.omg)

      assert result == :ok
      assert calculation.from_amount == 100
      assert calculation.from_token.uuid == context.eth.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == context.omg.uuid
      # Asserting `1 / rate` because we're using a reversed pair
      assert calculation.actual_rate == 1 / pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns an :exchange_pair_not_found error if the pair is not found", context do
      {result, code} = Exchange.calculate(nil, context.eth, 10, context.omg)

      assert result == :error
      assert code == :exchange_pair_not_found
    end
  end

  describe "calculate/4 with a nil `to_amount`" do
    test "returns the calculation using a direct pair", context do
      pair =
        insert(
          :exchange_pair,
          from_token: context.eth,
          to_token: context.omg,
          rate: 10.0,
          reversible: false
        )

      {result, calculation} = Exchange.calculate(10, context.eth, nil, context.omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == context.eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == context.omg.uuid
      assert calculation.actual_rate == pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns the calculation using a reversed pair", context do
      pair =
        insert(
          :exchange_pair,
          from_token: context.omg,
          to_token: context.eth,
          rate: 0.1,
          reversible: true
        )

      {result, calculation} = Exchange.calculate(10, context.eth, nil, context.omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == context.eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == context.omg.uuid
      # Asserting `1 / rate` because we're using a reversed pair
      assert calculation.actual_rate == 1 / pair.rate
      assert calculation.pair.uuid == pair.uuid
    end
  end

  describe "calculate/4 with both `from_amount` and `to_amount` given" do
    test "returns an :invalid_parameter error", context do
      {result, code, description} = Exchange.calculate(10, context.omg, 100, context.eth)

      assert result == :error
      assert code == :invalid_parameter
      assert description == "unable to calculate if amounts are already provided"
    end
  end

  describe "calculate/4 with nil `from_amount` and `to_amount`" do
    test "returns an :invalid_parameter error", context do
      {result, code, description} = Exchange.calculate(nil, context.eth, nil, context.omg)

      assert result == :error
      assert code == :invalid_parameter
      assert description == "an exchange requires from amount, to amount, or both"
    end
  end

  describe "calculate/4 with the same `from_token` and `to_token`" do
    test "returns a to_amount if to_amount is nil", context do
      {:ok, calculation} = Exchange.calculate(1000, context.eth, nil, context.eth)
      assert calculation.to_amount == 1000
    end

    test "returns a from_amount if from_amount is nil", context do
      {:ok, calculation} = Exchange.calculate(nil, context.eth, 2000, context.eth)
      assert calculation.from_amount == 2000
    end
  end
end
