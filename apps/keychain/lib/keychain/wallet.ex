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
  alias ExthCrypto.ECIES.ECDH
  alias ExthCrypto.Hash.Keccak

  @typep address :: Keychain.address()
  @typep resp(ret) :: ret | {:error, atom()}

  @doc """
  Generates a new wallet address and returns a wallet ID for futher access.

  Returns a tuple of `{:ok, {wallet_address, public_key}}`.
  """
  @spec generate :: resp({:ok, address()})
  def generate do
    {public_key, private_key} = ECDH.new_ecdh_keypair()

    <<4::size(8), key::binary-size(64)>> = public_key
    <<_::binary-size(12), wallet_address::binary-size(20)>> = Keccak.kec(key)

    wallet_address = Base.encode16(wallet_address, case: :lower)
    wallet_address = "0x#{wallet_address}"

    public_key_encoded = Base.encode16(public_key, case: :lower)
    private_key_encoded = Base.encode16(private_key, case: :lower)

    IO.inspect(private_key_encoded)

    {:ok, _} = Key.insert_private_key(wallet_address, private_key_encoded)
    {:ok, {wallet_address, public_key_encoded}}
  end
end
