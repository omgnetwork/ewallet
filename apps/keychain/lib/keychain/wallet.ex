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

  @pub_root_derivation_path "M/44'/60'/0'/0'"

  @doc """
  Generates a new wallet address and returns a wallet ID for futher access.

  Returns a tuple of `{:ok, {wallet_address, public_key}}`.
  """
  @spec generate :: resp({:ok, address()})
  def generate do
    {public_key, private_key} =
      :crypto.generate_key(:ecdh, :secp256k1, :crypto.strong_rand_bytes(32))

    <<4::size(8), key::binary-size(64)>> = public_key
    <<_::binary-size(12), wallet_address::binary-size(20)>> = Keccak.kec(key)

    wallet_address = Base.encode16(wallet_address, case: :lower)
    wallet_address = "0x#{wallet_address}"

    public_key_encoded = Base.encode16(public_key, case: :lower)
    private_key_encoded = Base.encode16(private_key, case: :lower)

    {:ok, _} =
      Key.insert(%{
        wallet_id: wallet_address,
        public_key: public_key_encoded,
        encrypted_private_key: private_key_encoded
      })

    {:ok, {wallet_address, public_key_encoded}}
  end

  @spec generate_hd :: {:ok, <<_::288>>}
  def generate_hd do
    %{mnemonic: _mnemonic, root_key: root_key} = BlockKeys.generate()
    public_key = CKD.derive(root_key, @pub_root_derivation_path)
    wallet_address = Ethereum.Address.from_xpub(public_key)
    uuid = UUID.generate()

    {:ok, _} =
      Key.insert(%{
        wallet_id: wallet_address,
        public_key: public_key,
        encrypted_private_key: root_key,
        uuid: uuid
      })

    {:ok, uuid}
  end

  @spec generate_child_account(any, any, any) :: <<_::16, _::_*8>> | {:error, :key_not_found}
  def generate_child_account(uuid, account_ref, deposit_ref) do
    case Key.public_key_for_uuid(uuid) do
      nil ->
        {:error, :invalid_uuid}

      public_key ->
        path = "M/#{account_ref}/#{deposit_ref}"
        Ethereum.address(public_key, path)
    end
  end
end
