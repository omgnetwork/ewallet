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

defmodule Utils.Helpers.Crypto do
  @moduledoc """
  A helper to perform crytographic operations
  """
  alias Plug.Crypto

  @spec generate_base64_key(non_neg_integer()) :: binary()
  def generate_base64_key(key_bytes) when is_integer(key_bytes) do
    key_bytes
    |> generate_key()
    |> Base.url_encode64(padding: false)
  end

  def generate_base32_key(key_bytes) when is_integer(key_bytes) do
    key_bytes
    |> generate_key()
    |> Base.encode32()
  end

  def generate_base16_key(key_bytes) when is_integer(key_bytes) do
    key_bytes
    |> generate_key()
    |> Base.encode16()
  end

  @spec generate_key(non_neg_integer()) :: binary()
  def generate_key(key_bytes) when is_integer(key_bytes) do
    :crypto.strong_rand_bytes(key_bytes)
  end

  @spec hash_secret(String.t()) :: String.t()
  def hash_secret(secret) do
    :crypto.hash(:sha384, secret)
    |> Base.encode16(padding: false)
    |> String.downcase()
  end

  @spec verify_secret(String.t(), String.t()) :: boolean
  def verify_secret(secret, hash) do
    case Base.url_decode64(secret, padding: false) do
      {:ok, decoded} ->
        decoded
        |> hash_secret()
        |> secure_compare(hash)

      :error ->
        false
    end
  end

  @spec hash_password(nil) :: nil
  def hash_password(nil), do: nil

  @spec hash_password(String.t()) :: String.t()
  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  @spec verify_password(String.t(), String.t()) :: boolean
  def verify_password(password, hash) do
    Bcrypt.verify_pass(password, hash)
  end

  @spec fake_verify :: false
  def fake_verify do
    Bcrypt.no_user_verify()
  end

  @spec secure_compare(String.t(), String.t()) :: boolean
  def secure_compare(left, right), do: Crypto.secure_compare(left, right)

  def fake_eth_address do
    data = 20 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
    "0x" <> data
  end
end
