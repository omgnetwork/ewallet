defmodule EWallet.ExchangeTest do
  use EWallet.DBCase
  alias EWallet.Exchange

  describe "validate/4 with the same token" do
    test "returns {:ok, calculation} if amounts are the same" do
      omg = insert(:token)

      {result, calculation} = Exchange.validate(10, omg, 10, omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == omg.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == omg.uuid
      assert calculation.actual_rate == 1
      assert calculation.pair == nil
    end

    test "returns a {:error, :exchange_invalid_rate} if amounts are different" do
      omg = insert(:token)

      {result, code} = Exchange.validate(10, omg, 100, omg)

      assert result == :error
      assert code == :exchange_invalid_rate
    end
  end

  describe "validate/4 with cross tokens" do
    test "returns {:ok, calculation} if the amounts match the rate" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 10.0, reversible: false)

      {result, calculation} = Exchange.validate(10, eth, 100, omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == omg.uuid
      assert calculation.actual_rate == pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns an :exchange_invalid_rate error if the amounts do not match the rate" do
      eth = insert(:token)
      omg = insert(:token)
      _ = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 10.0, reversible: false)

      # Using false rate of 100.0
      {result, code} = Exchange.validate(10, eth, 1000, omg)

      assert result == :error
      assert code == :exchange_invalid_rate
    end
  end

  describe "calculate/4 with a nil `from_amount`" do
    test "returns the calculation using a direct pair" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 0.1, reversible: false)

      {result, calculation} = Exchange.calculate(nil, eth, 10, omg)

      assert result == :ok
      assert calculation.from_amount == 100
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == omg.uuid
      assert calculation.actual_rate == pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns the calculation using a reversed pair" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: omg, to_token: eth, rate: 10.0, reversible: true)

      {result, calculation} = Exchange.calculate(nil, eth, 10, omg)

      assert result == :ok
      assert calculation.from_amount == 100
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == omg.uuid
      # Asserting `1 / rate` because we're using a reversed pair
      assert calculation.actual_rate == 1 / pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns an :exchange_pair_not_found error if the pair is not found" do
      eth = insert(:token)
      omg = insert(:token)

      {result, code} = Exchange.calculate(nil, eth, 10, omg)

      assert result == :error
      assert code == :exchange_pair_not_found
    end
  end

  describe "calculate/4 with a nil `to_amount`" do
    test "returns the calculation using a direct pair" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 10.0, reversible: false)

      {result, calculation} = Exchange.calculate(10, eth, nil, omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == omg.uuid
      assert calculation.actual_rate == pair.rate
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns the calculation using a reversed pair" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: omg, to_token: eth, rate: 0.1, reversible: true)

      {result, calculation} = Exchange.calculate(10, eth, nil, omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == omg.uuid
      # Asserting `1 / rate` because we're using a reversed pair
      assert calculation.actual_rate == 1 / pair.rate
      assert calculation.pair.uuid == pair.uuid
    end
  end

  describe "calculate/4 with both `from_amount` and `to_amount` given" do
    test "returns an :invalid_parameter error" do
      omg = insert(:token)
      eth = insert(:token)

      {result, code, description} = Exchange.calculate(10, omg, 100, eth)

      assert result == :error
      assert code == :invalid_parameter
      assert description == "unable to calculate if amounts are already provided"
    end
  end

  describe "calculate/4 with nil `from_amount` and `to_amount`" do
    test "returns an :invalid_parameter error" do
      eth = insert(:token)
      omg = insert(:token)

      {result, code, description} = Exchange.calculate(nil, eth, nil, omg)

      assert result == :error
      assert code == :invalid_parameter
      assert description == "an exchange requires from amount, to amount, or both"
    end
  end

  describe "calculate/4 with the same `from_token` and `to_token`" do
    test "returns a to_amount if to_amount is nil" do
      eth = insert(:token)
      {:ok, calculation} = Exchange.calculate(1000, eth, nil, eth)
      assert calculation.to_amount == 1000
    end

    test "returns a from_amount if from_amount is nil" do
      eth = insert(:token)
      {:ok, calculation} = Exchange.calculate(nil, eth, 2000, eth)
      assert calculation.from_amount == 2000
    end
  end
end
