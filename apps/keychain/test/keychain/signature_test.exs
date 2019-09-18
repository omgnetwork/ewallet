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

defmodule Keychain.SignatureTest do
  use Keychain.DBCase
  import Keychain.Factory
  alias ExthCrypto.Hash.Keccak
  alias Keychain.Signature

  describe "sign_transaction_hash/3" do
    test "returns an ECDSA signature (v,r,s) when given hash and wallet_id" do
      key = insert(:key)
      hash = Keccak.kec("some data")

      {:ok, {v, r, s}} = Signature.sign_transaction_hash(hash, key.wallet_id, 0)

      assert is_integer(v)
      assert is_integer(r)
      assert is_integer(s)

      assert byte_size(:binary.encode_unsigned(r)) == 32
      assert byte_size(:binary.encode_unsigned(s)) == 32
    end

    test "returns :invalid_address error if the wallet_id could not be found" do
      hash = Keccak.kec("some data")

      assert Signature.sign_transaction_hash(hash, "some_unknown_wallet_id") ==
               {:error, :invalid_address}
    end
  end

  describe "sign_transaction_hash/6" do
    test "returns an ECDSA signature when given hash, wallet_id and child key specified via account_ref & deposit_ref" do
      key = insert(:hd_key)
      hash = Keccak.kec("some data")

      {:ok, {v, r, s}} =
        Signature.sign_transaction_hash(hash, key.wallet_id, "M/44'/60'/0'/0'", 0, 0, 0)

      assert is_integer(v)
      assert is_integer(r)
      assert is_integer(s)

      assert byte_size(:binary.encode_unsigned(r)) == 32
      assert byte_size(:binary.encode_unsigned(s)) == 32
    end

    test "returns :invalid_address error if the uuid could not be found" do
      hash = Keccak.kec("some data")
      result = Signature.sign_transaction_hash(hash, "invalid address", "M/44'/60'/0'/0'", 0, 0)

      assert result == {:error, :invalid_address}
    end
  end

  describe "recover_public_key/5" do
    test "returns the public key of the given transaction hash and r s v values" do
      key = insert(:key)
      hash = Keccak.kec("some data")

      {:ok, {v, r, s}} = Signature.sign_transaction_hash(hash, key.wallet_id)
      {res, public_key} = Signature.recover_public_key(hash, r, s, v)

      assert res == :ok
      assert public_key == Base.decode16!(key.public_key, case: :lower)
    end

    test "returns the public key of the given transaction hash, r s v values and chain_id" do
      key = insert(:key)
      hash = Keccak.kec("some data")

      {:ok, {v, r, s}} = Signature.sign_transaction_hash(hash, key.wallet_id, 99)
      {res, public_key} = Signature.recover_public_key(hash, r, s, v, 99)

      assert res == :ok
      assert public_key == Base.decode16!(key.public_key, case: :lower)
    end
  end
end
