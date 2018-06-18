defmodule EWallet.Exchange.CalculatorTest do
  use EWallet.DBCase
  alias EWallet.Exchange.Calculator

  describe "calculate/4 with a nil `from_amount`" do
    test "returns the calculation using a direct pair" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 0.1, reversible: false)

      {result, calculation} = Calculator.calculate(nil, eth, 10, omg)

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

      {result, calculation} = Calculator.calculate(nil, eth, 10, omg)

      assert result == :ok
      assert calculation.from_amount == 100
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 10
      assert calculation.to_token.uuid == omg.uuid
      assert calculation.actual_rate == 1 / pair.rate # Because we're using a reversed pair
      assert calculation.pair.uuid == pair.uuid
    end

    test "returns an :exchange_pair_not_found error if the pair is not found" do
      eth = insert(:token)
      omg = insert(:token)

      {result, code} = Calculator.calculate(nil, eth, 10, omg)

      assert result == :error
      assert code == :exchange_pair_not_found
    end
  end

  describe "calculate/4 with a nil `to_amount`" do
    test "returns the calculation using a direct pair" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 10.0, reversible: false)

      {result, calculation} = Calculator.calculate(10, eth, nil, omg)

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

      {result, calculation} = Calculator.calculate(10, eth, nil, omg)

      assert result == :ok
      assert calculation.from_amount == 10
      assert calculation.from_token.uuid == eth.uuid
      assert calculation.to_amount == 100
      assert calculation.to_token.uuid == omg.uuid
      assert calculation.actual_rate == 1 / pair.rate # Because we're using a reversed pair
      assert calculation.pair.uuid == pair.uuid
    end
  end

  describe "calculate/4 with specified `from_amount` and `to_amount`" do
    test "returns the calculation if the rate is valid" do
      eth = insert(:token)
      omg = insert(:token)
      pair = insert(:exchange_pair, from_token: eth, to_token: omg, rate: 10.0, reversible: false)

      {result, calculation} = Calculator.calculate(10, eth, 100, omg)

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

      {result, code} = Calculator.calculate(10, eth, 1000, omg) # Using false rate of 100.0

      assert result == :error
      assert code == :exchange_invalid_rate
    end
  end

  describe "calculate/4 with nil `from_amount` and `to_amount`" do
    test "returns an :invalid_parameter error" do
      eth = insert(:token)
      omg = insert(:token)

      {result, code, description} = Calculator.calculate(nil, eth, nil, omg)

      assert result == :error
      assert code == :invalid_parameter
      assert description == "either `from_amount` or `to_amount` or both must be provided"
    end
  end

  describe "calculate/4 with the same `from_token` and `to_token`" do
    test "returns an :invalid_parameter error" do
      eth = insert(:token)

      {result, code, description} = Calculator.calculate(1, eth, 1, eth)

      assert result == :error
      assert code == :invalid_parameter
      assert description == "`from_token` and `to_token` must be different tokens"
    end
  end
end
