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

defmodule Keychain.Key do
  @moduledoc """
  Ecto Schema representing a key pair in keychain.
  """
  use Ecto.Schema
  alias Keychain.{Repo, Key}
  import Ecto.{Changeset, Query}

  @primary_key {:wallet_id, :string, []}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "keychain" do
    field(:encrypted_private_key, Keychain.Encrypted.Binary)
    timestamps()
  end

  @doc """
  Validates the keychain.
  """
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:wallet_id, :encrypted_private_key])
    |> validate_required([:wallet_id, :encrypted_private_key])
    |> unique_constraint(:wallet_id)
  end

  @doc """
  Retrieve a private key using wallet ID.
  """
  def private_key_for_wallet(wallet_id) do
    Key
    |> select([k], k.encrypted_private_key)
    |> where([k], k.wallet_id == ^wallet_id)
    |> Repo.one()
  end

  @doc """
  Create a new keychain with the passed attributes.
  """
  def insert_private_key(wallet_id, private_key) do
    %Key{}
    |> changeset(%{wallet_id: wallet_id, encrypted_private_key: private_key})
    |> Repo.insert()
  end
end
