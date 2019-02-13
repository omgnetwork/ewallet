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

defmodule ExternalLedger.Wallet do
  @moduledoc """
  Ecto Schema representing external ledger wallets. A wallet is made up of
  a unique address and the ID associated with it.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias ExternalLedger.Repo

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  @hot "hot"
  @cold "cold"

  def hot, do: @hot
  def cold, do: @cold

  @ethereum "ethereum"
  @omg_network "omg_network"

  def ethereum, do: @ethereum
  def omg_network, do: @omg_network

  schema "wallet" do
    field(:address, :string)
    field(:adapter, :string)
    field(:type, :string)
    field(:public_key, :string)
    field(:encrypted_private_key, ExternalLedger.Encrypted.String)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, ExternalLedger.Encrypted.Map, default: %{})

    timestamps()
  end

  @doc """
  Validate the wallet attributes.
  """
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = wallet, attrs) do
    wallet
    |> cast(attrs, [:address, :adapter, :type, :public_key, :encrypted_private_key, :metadata, :encrypted_metadata])
    |> validate_required([:address, :adapter, :type, :metadata, :encrypted_metadata])
    |> validate_format(:adapter, ~r/#{@ethereum}|#{@omg_network}_.*/)
    |> validate_format(:type, ~r/#{@hot}|#{@cold}_.*/)
    |> unique_constraint(:address)
  end

  @doc """
  Retrieve wallets using the specified addresses.
  """
  @spec all([String.t()]) :: [%__MODULE__{}]
  def all(addresses) do
    __MODULE__
    |> where([w], w.address in ^addresses)
    |> Repo.all()
  end

  @doc """
  Retrieve a wallet using the specified address.
  """
  @spec get(String.t()) :: %__MODULE__{} | nil
  def get(address) do
    get_by(address: address)
  end

  @doc """
  Retrieve a wallet using one or more fields.
  """
  @spec get_by(map()) :: %__MODULE__{} | nil
  def get_by(attrs) do
    Repo.get_by(__MODULE__, attrs)
  end

  @doc """
  Retrieve a wallet from the database using the specified address
  or insert a new one before returning it.
  """
  @spec get_or_insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def get_or_insert(%{"address" => address} = attrs) do
    case get(address) do
      nil ->
        insert(attrs)

      wallet ->
        {:ok, wallet}
    end
  end

  @doc """
  Create a new wallet with the passed attributes. With "on conflict: nothing",
  conflicts are ignored. No matter what, a fresh get query is made to get
  the current database record, be it the one inserted right before or
  one inserted by another concurrent process.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    changeset = changeset(%__MODULE__{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :address]

    case Repo.insert(changeset, opts) do
      {:ok, wallet} ->
        {:ok, get(wallet.address)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update the updated_at field for all wallets matching the given addresses.
  """
  @spec touch(String.t() | [String.t()]) :: {integer(), nil | [term()]}
  def touch(addresses) do
    addresses = List.wrap(addresses)

    Repo.update_all(
      from(w in __MODULE__, where: w.address in ^addresses),
      set: [updated_at: NaiveDateTime.utc_now()]
    )
  end

  @doc """
  Use a FOR UPDATE lock on the wallet records for which the current wallets
  will be calculated.
  """
  def lock(addresses) do
    addresses = List.wrap(addresses)

    Repo.all(
      from(
        w in __MODULE__,
        where: w.address in ^addresses,
        lock: "FOR UPDATE"
      )
    )
  end
end
