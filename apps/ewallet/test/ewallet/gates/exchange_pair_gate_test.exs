defmodule EWallet.ExchangePairGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.ExchangePairGate

  describe "insert/2" do
    test "inserts an exchange pair" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "name" => "Test pair",
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id
        })

      assert res == :ok
      assert is_list(pairs)
      assert Enum.count(pairs) == 1

      assert Enum.at(pairs, 0).name == "Test pair"
      assert Enum.at(pairs, 0).from_token_uuid == eth.uuid
      assert Enum.at(pairs, 0).to_token_uuid == omg.uuid
      assert Enum.at(pairs, 0).rate == 2.0
    end

    test "inserts an exchange pair along with its opposite pair if requested" do
      eth = insert(:token)
      omg = insert(:token)

      {res, pairs} =
        ExchangePairGate.insert(%{
          "name" => "Test pair",
          "rate" => 2.0,
          "from_token_id" => eth.id,
          "to_token_id" => omg.id,
          "create_opposite_pair" => true
        })

      assert res == :ok
      assert is_list(pairs)
      assert Enum.count(pairs) == 2

      # Asserts the direct pair
      assert Enum.at(pairs, 0).name == "Test pair"
      assert Enum.at(pairs, 0).rate == 2.0

      # Asserts the opposite pair
      assert Enum.at(pairs, 1).name == "Test pair (opposite pair)"
      assert Enum.at(pairs, 1).rate == 1 / 2.0
    end
  end

  describe "update/2" do
    test "updates an exchange pair" do
      pair = insert(:exchange_pair)

      {res, pair} =
        ExchangePairGate.update(pair.id, %{
          "name" => "Test pair updated",
          "rate" => 999
        })

      assert res == :ok
      assert pair.name == "Test pair updated"
      assert pair.rate == 999
    end

    test "returns :exchange_pair_id_not_found error if the exchange pair is not found" do
      {res, code} =
        ExchangePairGate.update("wrong_id", %{
          "name" => "Test pair updated"
        })

      assert res == :error
      assert code == :exchange_pair_id_not_found
    end
  end
end
