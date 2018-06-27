defmodule EWallet.AmountFormatterTest do
  use ExUnit.Case
  alias EWallet.AmountFormatter

  describe "format/2" do
    test "formats correctly given an amount and a subunit_to_unit" do
      res = AmountFormatter.format(123, 100)

      assert res == "1.23"
    end

    test "formats correctly given a subunit_to_unit bigger than amount" do
      res = AmountFormatter.format(123, 10_000)

      assert res == "0.0123"
    end

    test "formats correctly given an amount with trailing zeros" do
      res = AmountFormatter.format(1_000_000, 10)

      assert res == "100000"
    end
  end
end
