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
  alias BlockKeys.{CKD, Encoding}

  @type recovery_id :: <<_::8>>
  @type hash_v :: integer()
  @type hash_r :: integer()
  @type hash_s :: integer()

  @base_recovery_id 27
  @base_recovery_id_eip_155 35

  @doc """
  Returns a ECDSA signature (v,r,s) for a given hashed value.
  """
  @spec sign_transaction_hash(Keccak.keccak_hash(), String.t(), integer() | nil) ::
          {hash_v, hash_r, hash_s} | {:error, :invalid_address}
  def sign_transaction_hash(hash, wallet_id, chain_id \\ nil) do
    wallet_id
    |> Key.private_key_for_wallet()
    |> sign_if_found(hash, chain_id)
  end

  @doc """
  Returns a ECDSA signature (v,r,s) for a child key specified via account_ref & deposit_ref
  """
  @spec sign_with_child_key(
          Keccak.keccak_hash(),
          Ecto.UUID.t(),
          String.t(),
          Integer.t(),
          Integer.t(),
          integer() | nil
        ) ::
          {hash_v, hash_r, hash_s} | {:error, :invalid_uuid}
  def sign_with_child_key(hash, wallet_uuid, derivation_path, account_ref, deposit_ref, chain_id \\ nil) do
    case Key.private_key_for_uuid(wallet_uuid) do
      nil ->
        {:error, :invalid_uuid}

      xprv ->
        child_xprv = CKD.derive(xprv, derivation_path <> "/#{account_ref}/#{deposit_ref}")

        decoded = Encoding.decode_extended_key(child_xprv)
        <<_prefix::binary-1, pkey::binary-32>> = decoded[:key]
        do_sign(pkey, hash, chain_id)
    end
  end

  @doc """
  Attempts to recover the public key of a transaction hash given its r s v and chain_id values
  Returns {:ok, public_key}
  or
  {:error, reason} if failed
  """
  @spec recover_public_key(Keccak.keccak_hash(), hash_r(), hash_s(), hash_v(), integer()) ::
          {:ok, ExthCrypto.Key.public_key()} | {:error, String.t()}
  def recover_public_key(hash, r, s, v, chain_id \\ nil) do
    signature = encode_unsigned(r) <> encode_unsigned(s)

    recovery_id =
      if not is_nil(chain_id) and uses_chain_id?(v) do
        v - chain_id * 2 - @base_recovery_id_eip_155
      else
        v - @base_recovery_id
      end

    Signature.recover(hash, signature, recovery_id)
  end

  defp uses_chain_id?(v) do
    v >= @base_recovery_id_eip_155
  end

  defp sign_if_found(nil, _hash, _chain_id), do: {:error, :invalid_address}

  defp sign_if_found(private_key, hash, chain_id) do
    private_key
    |> from_hex()
    |> do_sign(hash, chain_id)
  end

  defp do_sign(decoded_p_key, hash, chain_id) do
    {_signature, r, s, recovery_id} = Signature.sign_digest(hash, decoded_p_key)

    recovery_id =
      case chain_id do
        nil -> @base_recovery_id + recovery_id
        c_id -> c_id * 2 + @base_recovery_id_eip_155 + recovery_id
      end

    {:ok, {recovery_id, r, s}}
  end
end
