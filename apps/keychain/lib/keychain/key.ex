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
  alias Ecto.UUID

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "keychain" do
    field(:wallet_address, :string)
    field(:public_key, :string)
    field(:private_key, Keychain.Encrypted.Binary)

    timestamps()
  end

  # Validates the keychain record.
  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:wallet_address, :public_key, :private_key])
    |> validate_required([:wallet_address, :public_key, :private_key])
    |> unique_constraint(:wallet_address)
  end

  @doc """
  Retrieve a private key using wallet address.
  """
  def private_key_for_wallet_address(address) do
    Key
    |> select([k], k.private_key)
    |> where([k], k.wallet_address == ^address)
    |> Repo.one()
  end

  def private_key_for_uuid(uuid) do
    Key
    |> select([k], k.private_key)
    |> where([k], k.uuid == ^uuid)
    |> Repo.one()
  end

  def public_key_for_wallet_address(address) do
    Key
    |> select([k], k.public_key)
    |> where([k], k.wallet_address == ^address)
    |> Repo.one()
  end

  def public_key_for_uuid(uuid) do
    Key
    |> select([k], k.public_key)
    |> where([k], k.uuid == ^uuid)
    |> Repo.one()
  end

  @doc """
  Create a new keychain with the passed attributes.
  """
  def insert(attrs) do
    %Key{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
