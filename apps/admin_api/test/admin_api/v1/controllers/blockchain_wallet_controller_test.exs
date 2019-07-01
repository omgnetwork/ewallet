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

defmodule AdminAPI.V1.BlockchainWalletControllerTest do
  use AdminAPI.ConnCase, async: true

  alias Utils.Helpers.DateFormatter

  describe "/blockchain_wallet.get" do
    test_with_auths "returns a wallet when given an existing blockchain wallet address" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      response =
        request("/blockchain_wallet.get", %{
          "address" => blockchain_wallet.address
        })

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "address" => "0x0000000000000000000000000000000000000123",
                 "name" => blockchain_wallet.name,
                 "type" => blockchain_wallet.type,
                 "object" => "blockchain_wallet",
                 "created_at" => DateFormatter.to_iso8601(blockchain_wallet.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(blockchain_wallet.updated_at)
               }
             }
    end

    test_with_auths "returns error when given non-existing wallet address" do
      insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      response = request("/blockchain_wallet.get", %{"address" => "0x0"})

      assert response == %{
               "data" => %{
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test_with_auths "returns error when not given address" do
      assert request("/blockchain_wallet.get", %{}) == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end
  end

  describe "/blockchain_wallet.all" do
    test_with_auths "returns all wallets when given pagination params" do
      # Inserts 2 wallets and 2 tokens
      blockchain_wallet_1 =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      blockchain_wallet_2 =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000456"})

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "start_after" => nil,
        "start_by" => "address"
      }

      response = request("/blockchain_wallet.all", attrs)

      assert response == %{
               "data" => %{
                 "data" => [
                   %{
                     "address" => "0x0000000000000000000000000000000000000123",
                     "name" => blockchain_wallet_1.name,
                     "type" => blockchain_wallet_1.type,
                     "object" => "blockchain_wallet",
                     "created_at" => DateFormatter.to_iso8601(blockchain_wallet_1.inserted_at),
                     "updated_at" => DateFormatter.to_iso8601(blockchain_wallet_1.updated_at)
                   },
                   %{
                     "address" => "0x0000000000000000000000000000000000000456",
                     "name" => blockchain_wallet_2.name,
                     "type" => blockchain_wallet_2.type,
                     "object" => "blockchain_wallet",
                     "created_at" => DateFormatter.to_iso8601(blockchain_wallet_2.inserted_at),
                     "updated_at" => DateFormatter.to_iso8601(blockchain_wallet_2.updated_at)
                   }
                 ],
                 "pagination" => %{
                   "count" => 2,
                   "is_last_page" => true,
                   "per_page" => 10,
                   "start_after" => nil,
                   "start_by" => "address"
                 },
                 "object" => "list"
               },
               "success" => true,
               "version" => "1"
             }
    end

    test_with_auths "returns a list of wallets and pagination data when given a start_after" do
      # Inserts 2 wallets and 2 tokens
      _blockchain_wallet_1 =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      blockchain_wallet_2 =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000456"})

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "start_after" => "0x0000000000000000000000000000000000000123",
        "start_by" => "address"
      }

      response = request("/blockchain_wallet.all", attrs)

      assert response == %{
               "data" => %{
                 "data" => [
                   %{
                     "address" => "0x0000000000000000000000000000000000000456",
                     "name" => blockchain_wallet_2.name,
                     "type" => blockchain_wallet_2.type,
                     "object" => "blockchain_wallet",
                     "created_at" => DateFormatter.to_iso8601(blockchain_wallet_2.inserted_at),
                     "updated_at" => DateFormatter.to_iso8601(blockchain_wallet_2.updated_at)
                   }
                 ],
                 "pagination" => %{
                   "count" => 1,
                   "is_last_page" => true,
                   "per_page" => 10,
                   "start_after" => "0x0000000000000000000000000000000000000123",
                   "start_by" => "address"
                 },
                 "object" => "list"
               },
               "success" => true,
               "version" => "1"
             }
    end
  end

  describe "/blockchain_wallet.get_balances" do
    test_with_auths "returns a list of balances and pagination data when given an existing blockchain wallet address" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 = insert(:token, %{blockchain_address: EthBlockchain.eth_address()})

      _token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      _token_3 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000002"})

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "per_page" => 2,
        "start_after" => nil,
        "start_by" => "id",
        "address" => blockchain_wallet.address
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["amount"]}
        end)

      assert length(balances) == 2
      assert Enum.member?(balances, {EthBlockchain.eth_address(), 123})
      assert Enum.member?(balances, {"0x0000000000000000000000000000000000000001", 123})
    end

    test_with_auths "returns a list of balances and pagination data when given a start_after" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 =
        insert(:token, %{
          id: "tkn_1",
          blockchain_address: EthBlockchain.eth_address()
        })

      token_2 =
        insert(:token, %{
          id: "tkn_2",
          blockchain_address: "0x0000000000000000000000000000000000000001"
        })

      _token_3 =
        insert(:token, %{
          id: "tkn_3",
          blockchain_address: "0x0000000000000000000000000000000000000002"
        })

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "per_page" => 2,
        "start_after" => token_2.id,
        "start_by" => "id",
        "address" => blockchain_wallet.address
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["id"], balance["amount"]}
        end)

      assert length(balances) == 1
      assert Enum.member?(balances, {"tkn_3", 123})
    end

    test_with_auths "returns a list of balances and pagination data when given an existing blockchain wallet address and a list of token addresses" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 = insert(:token, %{blockchain_address: EthBlockchain.eth_address()})

      _token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      _token_3 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000002"})

      attrs = %{
        "address" => blockchain_wallet.address,
        "token_addresses" => [
          EthBlockchain.eth_address(),
          "0x0000000000000000000000000000000000000001"
        ]
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["amount"]}
        end)

      assert length(balances) == 2
      assert Enum.member?(balances, {EthBlockchain.eth_address(), 123})
      assert Enum.member?(balances, {"0x0000000000000000000000000000000000000001", 123})
      refute Enum.member?(balances, {"0x0000000000000000000000000000000000000002", 123})
    end

    test_with_auths "returns a list of balances and pagination data when given an existing blockchain wallet address and a list of token addresses with a per_page" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 = insert(:token, %{blockchain_address: EthBlockchain.eth_address()})

      _token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      _token_3 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000002"})

      attrs = %{
        "per_page" => 1,
        "address" => blockchain_wallet.address,
        "token_addresses" => [
          "0x0000000000000000000000000000000000000001",
          EthBlockchain.eth_address()
        ]
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["amount"]}
        end)

      assert length(balances) == 1
      assert Enum.member?(balances, {EthBlockchain.eth_address(), 123})
      refute Enum.member?(balances, {"0x0000000000000000000000000000000000000001", 123})
      refute Enum.member?(balances, {"0x0000000000000000000000000000000000000002", 123})
    end

    test_with_auths "returns a list of balances and pagination data when given an existing blockchain wallet address and a list of token ids" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 =
        insert(:token, %{
          id: "tkn_1",
          blockchain_address: EthBlockchain.eth_address()
        })

      _token_2 =
        insert(:token, %{
          id: "tkn_2",
          blockchain_address: "0x0000000000000000000000000000000000000001"
        })

      _token_3 =
        insert(:token, %{
          id: "tkn_3",
          blockchain_address: "0x0000000000000000000000000000000000000002"
        })

      attrs = %{
        "address" => blockchain_wallet.address,
        "token_ids" => [
          "tkn_1",
          "tkn_2"
        ]
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["token"]["id"], balance["amount"]}
        end)

      assert length(balances) == 2
      assert Enum.member?(balances, {EthBlockchain.eth_address(), "tkn_1", 123})
      assert Enum.member?(balances, {"0x0000000000000000000000000000000000000001", "tkn_2", 123})
      refute Enum.member?(balances, {"0x0000000000000000000000000000000000000002", "tkn_3", 123})
    end

    test_with_auths "filters out non-blockchain tokens when not specifying ids" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 = insert(:token, %{blockchain_address: EthBlockchain.eth_address()})

      _token_2 = insert(:token, %{blockchain_address: nil})

      _token_3 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000002"})

      attrs = %{
        "address" => blockchain_wallet.address
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["amount"]}
        end)

      assert length(balances) == 2
      assert Enum.member?(balances, {EthBlockchain.eth_address(), 123})
      assert Enum.member?(balances, {"0x0000000000000000000000000000000000000002", 123})
    end

    test_with_auths "filters out inexistent tokens when specifying ids" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 =
        insert(:token, %{
          id: "tkn_1",
          blockchain_address: EthBlockchain.eth_address()
        })

      _token_2 =
        insert(:token, %{
          id: "tkn_2",
          blockchain_address: "0x0000000000000000000000000000000000000001"
        })

      _token_3 =
        insert(:token, %{
          id: "tkn_3",
          blockchain_address: "0x0000000000000000000000000000000000000002"
        })

      attrs = %{
        "address" => blockchain_wallet.address,
        "token_ids" => ["tkn_1", "tkn_2", "tkn_4"]
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["amount"]}
        end)

      assert length(balances) == 2
      assert Enum.member?(balances, {EthBlockchain.eth_address(), 123})
      assert Enum.member?(balances, {"0x0000000000000000000000000000000000000001", 123})
    end

    test_with_auths "filters out non-blockchain tokens when specifying ids" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      _token_1 =
        insert(:token, %{
          id: "tkn_1",
          blockchain_address: EthBlockchain.eth_address()
        })

      _token_2 = insert(:token, %{id: "tkn_2", blockchain_address: nil})

      _token_3 =
        insert(:token, %{
          id: "tkn_3",
          blockchain_address: "0x0000000000000000000000000000000000000002"
        })

      attrs = %{
        "address" => blockchain_wallet.address,
        "token_ids" => ["tkn_1", "tkn_2", "tkn_3"]
      }

      response = request("/blockchain_wallet.get_balances", attrs)

      assert response["success"] == true

      balances =
        Enum.map(response["data"]["data"], fn balance ->
          {balance["token"]["blockchain_address"], balance["amount"]}
        end)

      assert length(balances) == 2
      assert Enum.member?(balances, {EthBlockchain.eth_address(), 123})
      assert Enum.member?(balances, {"0x0000000000000000000000000000000000000002", 123})
    end

    test_with_auths "returns an error when given a non-existing address" do
      response =
        request("/blockchain_wallet.get_balances", %{
          "address" => "0x9999999999999999999999999999999999999999"
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns an error when address is missing" do
      response = request("/blockchain_wallet.get_balances", %{})

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end
end
