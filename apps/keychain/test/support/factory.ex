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

defmodule Keychain.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: Keychain.Repo
  alias BlockKeys.{CKD, Ethereum.Address}
  alias Ecto.UUID
  alias Keychain.{Key, Wallet}

  def key_factory do
    {public_key, private_key} = Wallet.generate_keypair()

    %Key{
      wallet_id: sequence(:email, &"wallet-id-#{&1}"),
      private_key: Base.encode16(private_key, case: :lower),
      public_key: Base.encode16(public_key, case: :lower),
      uuid: UUID.generate()
    }
  end

  def hd_key_factory do
    %{mnemonic: _mnemonic, root_key: root_key} = BlockKeys.generate()
    public_key = CKD.derive(root_key, "M/44'/60'/0'/0'")
    wallet_address = Address.from_xpub(public_key)

    %Key{
      wallet_id: wallet_address,
      private_key: root_key,
      public_key: public_key,
      uuid: UUID.generate()
    }
  end
end
