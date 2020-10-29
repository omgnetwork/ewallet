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

defmodule EWalletDB.Token.BlockchainTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWalletDB.{Token, Repo}
  alias Utils.Helpers.{Crypto, EIP55}

  @blockchain_identifier "ethereum"

  describe "insert_with_blockchain_address/1" do
    test_insert_ok(
      Token.Blockchain,
      :blockchain_identifier,
      Application.get_env(:ewallet_db, :rootchain_identifier),
      &Token.Blockchain.insert_with_blockchain_address/1,
      :external_blockchain_token
    )

    test_insert_ok(
      Token.Blockchain,
      :blockchain_status,
      Token.Blockchain.status_pending(),
      &Token.Blockchain.insert_with_blockchain_address/1,
      :external_blockchain_token
    )

    test_insert_error(
      Token.Blockchain,
      :blockchain_address,
      "0x123",
      [
        blockchain_address:
          {"is not a valid blockchain address", [validation: :invalid_blockchain_address]}
      ],
      &Token.Blockchain.insert_with_blockchain_address/1,
      :external_blockchain_token
    )

    test_insert_error(
      Token.Blockchain,
      :blockchain_identifier,
      "invalid_identifier",
      [
        blockchain_identifier:
          {"is not a valid blockchain identifier", [validation: :invalid_blockchain_identifier]}
      ],
      &Token.Blockchain.insert_with_blockchain_address/1,
      :external_blockchain_token
    )

    test_insert_error(
      Token.Blockchain,
      :blockchain_status,
      "123",
      [blockchain_status: {"is invalid", [validation: :inclusion]}],
      &Token.Blockchain.insert_with_blockchain_address/1,
      :external_blockchain_token
    )
  end

  describe "insert_with_contract_deployed/1" do
    test_insert_ok(
      Token.Blockchain,
      :blockchain_transaction_uuid,
      insert(:blockchain_transaction_rootchain).uuid,
      &Token.Blockchain.insert_with_contract_deployed/1,
      :internal_blockchain_token
    )

    test_insert_ok(
      Token.Blockchain,
      :contract_uuid,
      "some_uuid",
      &Token.Blockchain.insert_with_contract_deployed/1,
      :internal_blockchain_token
    )
  end

  describe "all_blockchain/2" do
    test "returns the list of tokens that have a blockchain address for the given blockchain identifier" do
      insert(:token, blockchain_address: "0x1", blockchain_identifier: "test")
      insert(:token, blockchain_address: "0x2", blockchain_identifier: "test")
      insert(:token, blockchain_address: "0x3", blockchain_identifier: "other")

      tokens = Token.Blockchain.all_blockchain("test")
      assert length(tokens) == 2
    end
  end

  describe "query_all_blockchain/1" do
    test "returns a query of tokens that have a blockchain address for the specified identifier" do
      assert Enum.empty?(Token.all())

      addr_1 = Crypto.fake_eth_address()
      addr_2 = Crypto.fake_eth_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: addr_1, blockchain_identifier: "ethereum"})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: addr_2, blockchain_identifier: "ethereum"})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} = :token |> params_for() |> Token.insert()

      token_addresses =
        Token.Blockchain.query_all_blockchain("ethereum")
        |> Repo.all()
        |> Enum.map(fn t -> t.blockchain_address end)

      assert length(token_addresses) == 2
      assert Enum.member?(token_addresses, addr_1)
      assert Enum.member?(token_addresses, addr_2)
    end
  end

  describe "query_all_unfinalized_blockchain/2" do
    test "returns a query of tokens that have not confirmed on the blockchain" do
      t_1 =
        insert(:internal_blockchain_token,
          blockchain_identifier: "ethereum",
          blockchain_status: Token.Blockchain.status_pending()
        )

      t_2 =
        insert(:internal_blockchain_token,
          blockchain_identifier: "ethereum",
          blockchain_status: Token.Blockchain.status_pending()
        )

      t_3 =
        insert(:internal_blockchain_token,
          blockchain_identifier: "ethereum",
          blockchain_status: Token.Blockchain.status_confirmed()
        )

      pending_tokens =
        "ethereum"
        |> Token.Blockchain.query_all_unfinalized_blockchain()
        |> Repo.all()
        |> Enum.map(fn t -> t.id end)

      assert length(pending_tokens) == 2

      assert Enum.member?(pending_tokens, t_1.id)
      assert Enum.member?(pending_tokens, t_2.id)
      refute Enum.member?(pending_tokens, t_3.id)
    end
  end

  describe "all_unfinalized_blockchain/2" do
    test "returns a list of tokens that have not confirmed on the blockchain" do
      t_1 =
        insert(:internal_blockchain_token,
          blockchain_identifier: "ethereum",
          blockchain_status: Token.Blockchain.status_pending()
        )

      t_2 =
        insert(:internal_blockchain_token,
          blockchain_identifier: "ethereum",
          blockchain_status: Token.Blockchain.status_pending()
        )

      t_3 =
        insert(:internal_blockchain_token,
          blockchain_identifier: "ethereum",
          blockchain_status: Token.Blockchain.status_confirmed()
        )

      pending_tokens =
        "ethereum"
        |> Token.Blockchain.all_unfinalized_blockchain()
        |> Enum.map(fn t -> t.id end)

      assert length(pending_tokens) == 2

      assert Enum.member?(pending_tokens, t_1.id)
      assert Enum.member?(pending_tokens, t_2.id)
      refute Enum.member?(pending_tokens, t_3.id)
    end
  end

  describe "query_all_by_blockchain_addresses/2" do
    test "returns a query of tokens that have an address matching in the provided list for the specified identifier" do
      addr_1 = Crypto.fake_eth_address()
      addr_2 = Crypto.fake_eth_address()
      addr_3 = Crypto.fake_eth_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: addr_1, blockchain_identifier: "ethereum"})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: addr_2, blockchain_identifier: "ethereum"})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: addr_3, blockchain_identifier: "ethereum"})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} = :token |> params_for() |> Token.insert()

      token_addresses =
        [addr_1, addr_2]
        |> Token.Blockchain.query_all_by_blockchain_addresses("ethereum")
        |> Repo.all()
        |> Enum.map(fn t -> t.blockchain_address end)

      assert length(token_addresses) == 2

      assert Enum.member?(token_addresses, addr_1)
      assert Enum.member?(token_addresses, addr_2)
      refute Enum.member?(token_addresses, addr_3)
    end

    test "ignore case" do
      addr_1 = Crypto.fake_eth_address()
      addr_2 = Crypto.fake_eth_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: String.downcase(addr_1)})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: String.downcase(addr_2)})
        |> Token.Blockchain.insert_with_blockchain_address()

      {:ok, _} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: Crypto.fake_eth_address()})
        |> Token.Blockchain.insert_with_blockchain_address()

      token_addresses =
        [String.upcase(addr_1), String.upcase(addr_2)]
        |> Token.Blockchain.query_all_by_blockchain_addresses("ethereum")
        |> Repo.all()
        |> Enum.map(fn t -> t.blockchain_address end)

      assert length(token_addresses) == 2

      assert Enum.member?(token_addresses, addr_1)
      assert Enum.member?(token_addresses, addr_2)
    end
  end

  describe "set_blockchain_address/2" do
    test "set the blockchain address of a token" do
      {:ok, token} = :token |> params_for() |> Token.insert()
      assert token.blockchain_address == nil
      assert token.blockchain_status == nil

      {:ok, token} =
        Token.Blockchain.set_blockchain_address(token, %{
          blockchain_address: "0x0000000000000000000000000000000000000000",
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_identifier: @blockchain_identifier,
          originator: %System{}
        })

      assert token.blockchain_address == "0x0000000000000000000000000000000000000000"
      assert token.blockchain_status == Token.Blockchain.status_pending()
    end

    test "fails to set an invalid blockchain status" do
      {:ok, token} = :token |> params_for() |> Token.insert()
      assert token.blockchain_address == nil
      assert token.blockchain_status == nil

      {status, changeset} =
        Token.Blockchain.set_blockchain_address(token, %{
          blockchain_address: "0x0000000000000000000000000000000000000000",
          blockchain_status: "invalid status",
          blockchain_identifier: @blockchain_identifier,
          originator: %System{}
        })

      assert status == :error
      refute changeset.valid?
    end

    test "fails to set an invalid blockchain address" do
      {:ok, token} = :token |> params_for() |> Token.insert()
      assert token.blockchain_address == nil
      assert token.blockchain_status == nil

      {status, changeset} =
        Token.Blockchain.set_blockchain_address(token, %{
          blockchain_address: "123",
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_identifier: @blockchain_identifier,
          originator: %System{}
        })

      assert status == :error
      refute changeset.valid?
    end

    test "fails to set an valid blockchain address with an invalid identifier" do
      {:ok, token} = :token |> params_for() |> Token.insert()
      assert token.blockchain_address == nil
      assert token.blockchain_status == nil

      {status, changeset} =
        Token.Blockchain.set_blockchain_address(token, %{
          blockchain_address: "0x0000000000000000000000000000000000000000",
          blockchain_status: "invalid status",
          blockchain_identifier: "invalid",
          originator: %System{}
        })

      assert status == :error
      refute changeset.valid?
    end

    test "fails to set a blockchain address to a token with an existing blockchain address" do
      address_1 = Crypto.fake_eth_address()
      address_2 = Crypto.fake_eth_address()

      {:ok, token} =
        :external_blockchain_token
        |> params_for(%{blockchain_address: address_1})
        |> Token.Blockchain.insert_with_blockchain_address()

      assert token.blockchain_address != nil

      {status, changeset} =
        Token.Blockchain.set_blockchain_address(token, %{
          blockchain_address: address_2,
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_identifier: @blockchain_identifier,
          originator: %System{}
        })

      assert status == :error
      refute changeset.valid?
    end

    test "saves the blockchain address in lower case" do
      address = Crypto.fake_eth_address()
      {:ok, eip55_address} = EIP55.encode(address)

      {:ok, token} = :token |> params_for() |> Token.insert()

      {:ok, updated_token} =
        Token.Blockchain.set_blockchain_address(token, %{
          blockchain_address: eip55_address,
          blockchain_status: Token.Blockchain.status_pending(),
          blockchain_identifier: @blockchain_identifier,
          originator: %System{}
        })

      assert eip55_address != String.downcase(address)
      assert updated_token.blockchain_address == String.downcase(address)
    end
  end
end
