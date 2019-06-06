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

  import Utils.Helpers.Encoding

  alias Keychain.Key
  alias ExthCrypto.Hash.Keccak
  alias ExthCrypto.Signature

  @type recovery_id :: <<_::8>>
  @type hash_v :: integer()
  @type hash_r :: integer()
  @type hash_s :: integer()

  @base_recovery_id 27
  @base_recovery_id_eip_155 35

  @doc """
  Returns a ECDSA signature (v,r,s) for a given hashed value.
  This implementes Eq.(207) of the Yellow Paper.
  """
  @spec sign_transaction_hash(Keccak.keccak_hash(), String.t(), integer() | nil) ::
          {hash_v, hash_r, hash_s}
  def sign_transaction_hash(hash, wallet_address, chain_id \\ nil) do
    private_key = wallet_address |> Key.private_key_for_wallet() |> from_hex()

    {_signature, r, s, recovery_id} = Signature.sign_digest(hash, private_key)

    recovery_id =
      case chain_id do
        nil -> @base_recovery_id + recovery_id
        c_id -> c_id * 2 + @base_recovery_id_eip_155 + recovery_id
      end

    {recovery_id, r, s}
  end
end
