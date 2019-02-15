# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule ExternalLedgerDB.Token do
  @moduledoc """
  Ecto Schema representing external ledger tokens. Tokens are made up of an
  id (e.g. tok_ABC_1234) and the associated UUID in the eWallet DB.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ExternalLedgerDB.Repo

  @behaviour Utils.Ledgers.TokenSchema

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  @ethereum "ethereum"
  @omg_network "omg_network"

  def ethereum, do: @ethereum
  def omg_network, do: @omg_network

  schema "token" do
    field(:id, :string)
    field(:adapter, :string)
    field(:contract_address, :string)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, ExternalLedgerDB.Encrypted.Map, default: %{})

    timestamps()
  end

  @doc """
  Validate the token attributes.
  """
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = token, attrs) do
    token
    |> cast(attrs, [
      :id,
      :adapter,
      :contract_address,
      :metadata,
      :encrypted_metadata
    ])
    |> validate_required([
      :id,
      :adapter,
      :contract_address,
      :metadata,
      :encrypted_metadata
    ])
    |> validate_inclusion(:adapter, [@ethereum, @omg_network])
    |> unique_constraint(:id)
    |> unique_constraint(:contract_address)
  end

  @doc """
  Retrieve a token using the specified ID.
  """
  @spec get(String.t()) :: %__MODULE__{} | nil
  def get(id) do
    Repo.get_by(__MODULE__, id: id)
  end

  @doc """
  Retrieve a token using one or more fields.
  """
  @spec get_by(map()) :: %__MODULE__{} | nil
  def get_by(attrs) do
    Repo.get_by(__MODULE__, attrs)
  end

  @doc """
  Retrieve a token from the database using the specified id
  or insert a new one before returning it.
  """
  @spec get_or_insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def get_or_insert(%{"id" => id} = attrs) do
    case get(id) do
      nil ->
        insert(attrs)

      token ->
        {:ok, token}
    end
  end

  @doc """
  Create a new token with the passed attributes. With "on conflict: nothing",
  conflicts are ignored. No matter what, a fresh get query is made to get
  the current database record, be it the one inserted right before or
  one inserted by another concurrent process.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    changeset = changeset(%__MODULE__{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :id]

    case Repo.insert(changeset, opts) do
      {:ok, token} ->
        {:ok, get(token.id)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
