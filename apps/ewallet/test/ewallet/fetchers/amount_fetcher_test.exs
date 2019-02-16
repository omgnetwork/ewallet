# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.AmountFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
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
                "Invalid parameter provided. `amount` not allowed when exchanging values. Use `from_amount` and/or `to_amount`."}
    end

    test "sets the amount in from_amount and to_amount" do
      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "amount" => 100
          },
          %{},
          %{}
        )

      assert res == :ok
      assert from == %{from_amount: 100}
      assert to == %{to_amount: 100}
      assert exchange == %{}
    end

    test "supports string integer" do
      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "amount" => "100"
          },
          %{},
          %{}
        )

      assert res == :ok
      assert from == %{from_amount: 100}
      assert to == %{to_amount: 100}
      assert exchange == %{}
    end

    test "returns an error if amount is not an integer (float)" do
      res =
        AmountFetcher.fetch(
          %{
            "amount" => 100.2
          },
          %{},
          %{}
        )

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `amount` is not an integer: 100.2"}
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

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. String number is not a valid number: 'fake'."}
    end
  end

  describe "fetch/3 with from_amount/to_amount" do
    test "sets from_amount and to_amount when valid integer" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "from_amount" => 100,
            "to_amount" => 200
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 100
      assert to[:to_amount] == 200
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "support string integers" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "from_amount" => "100",
            "to_amount" => "200"
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 100
      assert to[:to_amount] == 200
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "sets from_amount only when sending nil to_amount with exchange pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      {res, from, to, exchange} =
        AmountFetcher.fetch(
          %{
            "from_amount" => 100,
            "to_amount" => nil
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 100
      assert to[:to_amount] == 200
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
            "from_amount" => 100,
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
            "from_amount" => 100
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 100
      assert to[:to_amount] == 200
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
            "from_amount" => 100
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
            "to_amount" => 200
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 100
      assert to[:to_amount] == 200
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
            "to_amount" => 200
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
            "to_amount" => 200
          },
          %{from_token: token_1},
          %{to_token: token_2}
        )

      assert res == :ok
      assert from[:from_amount] == 100
      assert to[:to_amount] == 200
      assert exchange[:actual_rate] == 2
      assert exchange[:calculated_at] != nil
      assert exchange[:pair_uuid] == pair.uuid
    end

    test "returns an error when exchange pair is not found" do
      token_1 = insert(:token)
      token_2 = insert(:token)

      res =
        AmountFetcher.fetch(
          %{
            "to_amount" => 200
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
                "Invalid parameter provided. String numbers are not valid numbers: 'fake, fake'."}
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
               {:error, :invalid_parameter,
                "Invalid parameter provided. String number is not a valid number: 'fake'."}
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
               {:error, :invalid_parameter,
                "Invalid parameter provided. String number is not a valid number: 'fake'."}
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
               {:error, :invalid_parameter,
                "Invalid parameter provided. `amount`, `from_amount` or `to_amount` is required."}
    end
  end

  describe "fetch/3 with invalid params" do
    test "returns an error when sending nil to_amount" do
      res = AmountFetcher.fetch(%{}, %{}, %{})

      assert res ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `amount`, `from_amount` or `to_amount` is required."}
    end
  end
end
