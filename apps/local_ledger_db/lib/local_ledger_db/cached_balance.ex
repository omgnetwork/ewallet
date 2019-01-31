# Copyright 2018 OmiseGO Pte Ltd
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

defmodule LocalLedgerDB.CachedBalance do
  @moduledoc """
  Ecto Schema representing a cached balance.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias LocalLedgerDB.{CachedBalance, Repo, Wallet}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "cached_balance" do
    field(:amounts, :map)
    field(:computed_at, :naive_datetime_usec)

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
  end

  @doc """
  Validate the cached balance attributes.
  """
  def changeset(%CachedBalance{} = balance, attrs) do
    balance
    |> cast(attrs, [:amounts, :wallet_address, :computed_at])
    |> validate_required([:amounts, :wallet_address, :computed_at])
    |> foreign_key_constraint(:wallet_address)
  end

  @doc """
  Retrieve a list of cached balances using the specified addresses.
  """
  def all(addresses) do
    CachedBalance
    |> distinct([c], c.wallet_address)
    |> where([c], c.wallet_address in ^addresses)
    |> order_by([c], desc: c.wallet_address, desc: c.computed_at)
    |> Repo.all()
  end

  @doc """
  Retrieve a cached balance using the specified address.
  """
  def get(address) do
    CachedBalance
    |> where([c], c.wallet_address == ^address)
    |> order_by([c], desc: c.computed_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Insert a cached balance.
  """
  def insert(attrs) do
    %CachedBalance{}
    |> CachedBalance.changeset(attrs)
    |> Repo.insert()
  end
end
