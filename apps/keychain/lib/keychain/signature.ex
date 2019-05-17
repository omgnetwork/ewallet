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

defmodule Keychain.Signature do
  @moduledoc false

  alias Keychain.Key
  alias ExthCrypto.Hash.Keccak

  @type recovery_id :: <<_::8>>
  @type hash_v :: integer()
  @type hash_r :: integer()
  @type hash_s :: integer()

  # The follow are the maximum value for x in the signature, as defined in Eq.(212)
  @base_recovery_id 27

  @doc """
  Returns a ECDSA signature (v,r,s) for a given hashed value.
  This implementes Eq.(207) of the Yellow Paper.
  """
  @spec sign_transaction_hash(Keccak.keccak_hash(), String.t()) ::
          {hash_v, hash_r, hash_s}
  def sign_transaction_hash(hash, wallet_address) do
    private_key = Key.private_key_for_wallet(wallet_address)

    {:ok, <<r::size(256), s::size(256)>>, recovery_id} =
      :libsecp256k1.ecdsa_sign_compact(hash, private_key, :default, <<>>)

    recovery_id = @base_recovery_id + recovery_id

    {recovery_id, r, s}
  end
end
