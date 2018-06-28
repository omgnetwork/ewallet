defmodule EWallet.AmountFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.AmountFetcher

  describe "fetch/3 with amount" do
    test "returns error when passing amount and from_token_id/to_token_id" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "amount" => 0,
            "from_token_id" => token_1.id,
            "to_token_id" => token_2.id
          },
          %{},
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "'amount' not allowed when exchanging values. Use from_amount and/or to_amount."}
    end

    test "sets the amount in from_amount and to_amount" do
      res =
        AmountFetcher.fetch(
          %{
            "amount" => 1
          },
          %{},
          %{}
        )

      assert res == {:ok, %{from_amount: 1}, %{to_amount: 1}, %{}}
    end

    test "returns an error if amount is not an integer (float)" do
      res =
        AmountFetcher.fetch(
          %{
            "amount" => 1.2
          },
          %{},
          %{}
        )

      assert res == {:error, :invalid_parameter, "'amount' is not a number: 1.2"}
    end

    test "returns an error if amount is not an integer (string)" do
      res =
        AmountFetcher.fetch(
          %{
            "amount" => "fake"
          },
          %{},
          %{}
        )

      assert res == {:error, :invalid_parameter, "'amount' is not a number: fake"}
    end
  end

  describe "fetch/3 with from_amount/to_amount" do
    test "sets from_amount and to_amount when valid integer" do
      res =
        AmountFetcher.fetch(
          %{
            "from_amount" => 1,
            "to_amount" => 1
          },
          %{},
          %{}
        )

      assert res == {:ok, %{from_amount: 1}, %{to_amount: 1}, %{}}
    end

    test "sets from_amount only when sending nil to_amount with exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "from_amount" => 1,
            "to_amount" => nil
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 1
      assert to[:to_amount] == 2
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "sets from_amount only when sending nil to_amount without exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "from_amount" => 1,
            "to_amount" => nil
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == {:error, :exchange_pair_not_found}
    end

    test "sets from_amount only when not sending to_amount with exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "from_amount" => 1
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 1
      assert to[:to_amount] == 2
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "sets from_amount only when not sending to_amount without exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "from_amount" => 1
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == {:error, :exchange_pair_not_found}
    end

    test "sets to_amount only when sending nil from_amount with exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "from_amount" => nil,
            "to_amount" => 2
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 1
      assert to[:to_amount] == 2
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "sets to_amount only when sending nil from_amount without exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "from_amount" => nil,
            "to_amount" => 2
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == {:error, :exchange_pair_not_found}
    end

    test "sets to_amount only when not sending from_amount with exchange rate" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "to_amount" => 2
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 1
      assert to[:to_amount] == 2
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "sets to_amount only when not sending from_amount without exchange rate" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "to_amount" => 2
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == {:error, :exchange_pair_not_found}
    end

    test "returns an error when sending invalid from_amount and to_amount" do
      res =
        AmountFetcher.fetch(
          %{
            "from_amount" => "fake",
            "to_amount" => "fake"
          },
          %{},
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "'from_amount' / 'to_amount' are not valid: fake / fake"}
    end

    test "returns an error when sending invalid from_amount" do
      res =
        AmountFetcher.fetch(
          %{
            "from_amount" => "fake"
          },
          %{},
          %{}
        )

      assert res ==
               {:error, :invalid_parameter, "'amount', 'from_amount' or 'to_amount' is required."}
    end

    test "returns an error when sending invalid to_amount" do
      res =
        AmountFetcher.fetch(
          %{
            "to_amount" => "fake"
          },
          %{},
          %{}
        )

      assert res ==
               {:error, :invalid_parameter, "'amount', 'from_amount' or 'to_amount' is required."}
    end

    test "returns an error when sending nil to_amount" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "to_amount" => nil
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res ==
               {:error, :invalid_parameter, "'amount', 'from_amount' or 'to_amount' is required."}
    end
  end

  describe "fetch/3 with invalid params" do
    test "returns an error when sending nil to_amount" do
      res = AmountFetcher.fetch(%{}, %{}, %{})

      assert res ==
               {:error, :invalid_parameter, "'amount', 'from_amount' or 'to_amount' is required."}
    end
  end
end
