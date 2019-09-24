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

defmodule Keychain.Wallet do
  @moduledoc false

  alias Keychain.Key
  alias ExthCrypto.Hash.Keccak
  alias Ecto.UUID
  alias BlockKeys.{CKD, Ethereum, Ethereum.Address}

  @typep address :: Keychain.address()
  @typep resp(ret) :: ret | {:error, atom()}

  @root_derivation_path "M/44'/60'/0'/0'"

  @doc """
  Returns the root derivation path used as the base for
  generating the actual wallet's derivation path.
  """
  def root_derivation_path, do: @root_derivation_path

  @doc """
  Generates a new wallet address and returns a wallet ID for futher access.

  Returns a tuple of `{:ok, {wallet_address, public_key}}`.
  """
  @spec generate :: resp({:ok, address()})
  def generate do
    {public_key, private_key} = generate_keypair()
    <<4::size(8), key::binary-size(64)>> = public_key
    <<_::binary-size(12), wallet_address::binary-size(20)>> = Keccak.kec(key)

    wallet_address = Base.encode16(wallet_address, case: :lower)
    wallet_address = "0x#{wallet_address}"

    public_key_encoded = Base.encode16(public_key, case: :lower)
    private_key_encoded = Base.encode16(private_key, case: :lower)

    {:ok, _} =
      Key.insert(%{
        wallet_address: wallet_address,
        public_key: public_key_encoded,
        private_key: private_key_encoded
      })

    {:ok, {wallet_address, public_key_encoded}}
  end

  @spec generate_keypair() :: {public_key :: <<_::65>>, private_key :: <<_::32>>}
  def generate_keypair do
    :crypto.generate_key(:ecdh, :secp256k1, :crypto.strong_rand_bytes(32))
  end

  @spec generate_hd :: {:ok, String.t()}
  def generate_hd do
    %{mnemonic: _mnemonic, root_key: root_key} = BlockKeys.generate()
    public_key = CKD.derive(root_key, @root_derivation_path)
    wallet_address = Address.from_xpub(public_key)
    uuid = UUID.generate()

    Key.insert(%{
      wallet_address: wallet_address,
      public_key: public_key,
      private_key: root_key,
      uuid: uuid
    })
  end

  @spec derive_child_address(String.t(), integer(), integer()) ::
          String.t() | {:error, :key_not_found}
  def derive_child_address(keychain_uuid, wallet_ref, deposit_ref) do
    case Key.public_key_for_uuid(keychain_uuid) do
      nil ->
        {:error, :key_not_found}

      public_key ->
        path = "M/#{wallet_ref}/#{deposit_ref}"
        Ethereum.address(public_key, path)
    end
  end
end
