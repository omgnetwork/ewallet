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

defmodule EWallet.Web.MatchParserTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Web.{MatchParser, MatchAllQuery, MatchAnyQuery, Preloader}
  alias EWalletDB.{Account, Repo, Transaction}

  describe "build_query/3" do
    test "returns distinct records in a *-many filter" do
      account_1 = insert(:account)
      account_2 = insert(:account)

      token_1 = insert(:token, account: account_1)
      key_1 = insert(:key, account: account_1)

      attrs = [
        %{
          "field" => "tokens.symbol",
          "comparator" => "eq",
          "value" => token_1.symbol
        },
        %{
          "field" => "keys.access_key",
          "comparator" => "eq",
          "value" => key_1.access_key
        }
      ]

      query =
        MatchParser.build_query(
          Account,
          attrs,
          [tokens: [:symbol], keys: [:access_key]],
          true,
          MatchAllQuery
        )

      result = Repo.all(query)

      assert Enum.count(result) == 1
      assert Enum.all?(result, fn account -> account.id == account_1.id end)
      refute Enum.any?(result, fn account -> account.id == account_2.id end)
    end

    test "returns error if a filter param is missing" do
      _txn = insert(:transaction, from_amount: 100)

      attrs = [
        %{
          "field" => "from_amount",
          "comparator" => "eq"
          # "value" => txn.from_amount
        }
      ]

      {res, code, params} = MatchParser.build_query(Transaction, attrs, [], true, MatchAllQuery)

      assert res == :error
      assert code == :missing_filter_param
      assert params == %{"comparator" => "eq", "field" => "from_amount"}
    end

    test "returns error if filtering is not allowed on the field" do
      txn = insert(:transaction, from_amount: 100)

      attrs = [
        %{
          "field" => "from_amount",
          "comparator" => "eq",
          "value" => txn.from_amount
        }
      ]

      result = MatchParser.build_query(Transaction, attrs, [], true, MatchAllQuery)

      assert result == {:error, :not_allowed, "from_amount"}
    end
  end

  describe "build_query/3 with field definitions" do
    test "supports field tuples in the whitelist" do
      whitelist = [uuid: :uuid]

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      attrs = [
        %{
          "field" => "uuid",
          "comparator" => "eq",
          "value" => account_2.uuid
        }
      ]

      query = MatchParser.build_query(Account, attrs, whitelist, true, MatchAllQuery)
      result = Repo.all(query)

      refute Enum.any?(result, fn acc -> acc.id == account_1.id end)
      assert Enum.any?(result, fn acc -> acc.id == account_2.id end)
      refute Enum.any?(result, fn acc -> acc.id == account_3.id end)
    end
  end

  describe "build_query/3 with nested fields" do
    test "supports more than 5 associations are referenced" do
      whitelist = [
        from_user: [:id],
        to_user: [:id],
        from_token: [:id],
        to_token: [:id],
        from_wallet: [:id],
        to_wallet: [:id]
      ]

      attrs = [
        %{"field" => "from_user.id", "comparator" => "eq", "value" => 1234},
        %{"field" => "to_user.id", "comparator" => "eq", "value" => 1234},
        %{"field" => "from_token.id", "comparator" => "eq", "value" => 1234},
        %{"field" => "to_token.id", "comparator" => "eq", "value" => 1234},
        %{"field" => "from_wallet.id", "comparator" => "eq", "value" => 1234},
        %{"field" => "to_wallet.id", "comparator" => "eq", "value" => 1234}
      ]

      assert %Ecto.Query{} =
                MatchParser.build_query(Transaction, attrs, whitelist, true, MatchAllQuery)
    end

    test "returns error if filtering is not allowed on the field" do
      whitelist = [from_token: [:email]]

      _txn_1 = insert(:transaction)
      txn_2 = insert(:transaction)
      _txn_3 = insert(:transaction)

      {:ok, txn_2} = Preloader.preload_one(txn_2, :from_token)

      attrs = [
        %{
          "field" => "from_token.name",
          "comparator" => "eq",
          "value" => txn_2.from_token.name
        }
      ]

      {res, code, params} =
        MatchParser.build_query(Transaction, attrs, whitelist, true, MatchAllQuery)

      assert res == :error
      assert code == :not_allowed
      assert params == "from_token.name"
    end
  end

  describe "build_query/3 with multiple conditions" do
    test "returns only records that match all conditions" do
      txn_1 = insert(:transaction, status: "pending", type: "internal")
      txn_2 = insert(:transaction, status: "confirmed", type: "internal")
      txn_3 = insert(:transaction, status: "pending", type: "external")
      txn_4 = insert(:transaction, status: "confirmed", type: "external")

      attrs = [
        %{
          "field" => "status",
          "comparator" => "eq",
          "value" => "confirmed"
        },
        %{
          "field" => "type",
          "comparator" => "eq",
          "value" => "internal"
        }
      ]

      query = MatchParser.build_query(Transaction, attrs, [:status, :type], true, MatchAllQuery)
      result = Repo.all(query)

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_4.id end)
    end
  end

  describe "build_query/3 one after another" do
    test "does not throw an error about 'only distinct expression is allowed'" do
      txn_1 = insert(:transaction, status: "pending", type: "internal")
      txn_2 = insert(:transaction, status: "confirmed", type: "internal")
      txn_3 = insert(:transaction, status: "pending", type: "external")
      txn_4 = insert(:transaction, status: "confirmed", type: "external")

      attrs = [
        %{
          "field" => "status",
          "comparator" => "eq",
          "value" => "confirmed"
        },
        %{
          "field" => "type",
          "comparator" => "eq",
          "value" => "internal"
        }
      ]

      result =
        Transaction
        |> MatchParser.build_query(attrs, [:status, :type], true, MatchAllQuery)
        |> MatchParser.build_query(attrs, [:status, :type], false, MatchAnyQuery)
        |> Repo.all()

      refute Enum.any?(result, fn txn -> txn.id == txn_1.id end)
      assert Enum.any?(result, fn txn -> txn.id == txn_2.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_3.id end)
      refute Enum.any?(result, fn txn -> txn.id == txn_4.id end)
    end
  end
end
