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
    field(:cached_count, :integer)

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
  end

  defp changeset(%CachedBalance{} = balance, attrs) do
    balance
    |> cast(attrs, [:amounts, :wallet_address, :cached_count, :computed_at])
    |> validate_required([:amounts, :wallet_address, :cached_count, :computed_at])
    |> foreign_key_constraint(:wallet_address)
  end

  @doc """
  Retrieve a list of cached balances using the specified addresses.
  """
  @spec all([String.t()]) :: [%CachedBalance{}]
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
  @spec get(String.t()) :: %CachedBalance{} | nil
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
  @spec insert(map()) :: {:ok, %CachedBalance{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %CachedBalance{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Delete all cached balances for the given address(es) since the given computed date and time.
  """
  @spec delete_since(String.t() | [String.t()], NaiveDateTime.t()) ::
          {:ok, num_deleted :: integer()}
  def delete_since(addresses, computed_at) do
    addresses = List.wrap(addresses)

    {num_deleted, _} =
      CachedBalance
      |> where([c], c.wallet_address in ^addresses)
      |> where([c], c.computed_at >= ^computed_at)
      |> Repo.delete_all()

    {:ok, num_deleted}
  end
end
