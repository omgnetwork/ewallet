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

defmodule EWalletDB.BlockchainWallet do
  @moduledoc """
  Ecto Schema representing a blockchain wallet.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  import EWalletDB.Validator
  import EWalletDB.Helpers.Preloader

  alias Ecto.UUID
  alias EWalletDB.{Repo, BlockchainWallet}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  @hot "hot"
  @cold "cold"
  @wallet_types [@hot, @cold]

  def type_hot, do: @hot
  def type_cold, do: @cold

  schema "blockchain_wallet" do
    # Blockchain wallets don't have an external ID. Use `address` instead.
    field(:address, :string)
    field(:name, :string)
    field(:public_key, :string)
    field(:type, :string)

    activity_logging()
    timestamps()
  end

  defp insert_shared_changeset(%BlockchainWallet{} = wallet, attrs) do
    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :uuid,
        :address,
        :name,
        :type
      ],
      required: [:address, :name, :type]
    )
    |> unique_constraint(:address)
    |> unique_constraint(:name)
    |> validate_immutable(:address)
    |> validate_inclusion(:type, @wallet_types)
    |> validate_length(:address, count: :bytes, max: 255)
    |> validate_length(:name, count: :bytes, max: 255)
  end

  defp insert_hot_changeset(%BlockchainWallet{} = wallet, attrs) do
    shared = insert_shared_changeset(wallet, attrs)

    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :public_key
      ],
      required: [:public_key]
    )
    |> validate_immutable(:public_key)
    |> validate_inclusion(:type, [@hot])
    |> validate_length(:public_key, count: :bytes, max: 255)
    |> merge(shared)
  end

  defp insert_cold_changeset(%BlockchainWallet{} = wallet, attrs) do
    wallet
    |> insert_shared_changeset(attrs)
    |> validate_inclusion(:type, [@cold])
  end

  def get_primary_hot_wallet do
    :ewallet_db
    |> Application.get_env(:primary_hot_wallet)
    |> get("hot")
  end

  @doc """
  Retrieves a blockchain wallet using its address.
  """
  @spec get(String.t(), String.t()) :: %BlockchainWallet{} | nil | no_return()
  def get(nil, _), do: nil

  def get(address, type) do
    get_by(%{address: address, type: type})
  end

  @doc """
  Retrieves a blockchain wallet using one or more fields.
  """
  @spec get_by(fields :: map() | keyword(), opts :: keyword()) ::
          %BlockchainWallet{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    BlockchainWallet
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Create a new blockchain wallet with the passed attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}}
  def insert(%{"type" => @hot} = attrs) do
    %BlockchainWallet{}
    |> insert_hot_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  def insert(%{"type" => @cold} = attrs) do
    %BlockchainWallet{}
    |> insert_cold_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  def insert(attrs) do
    %BlockchainWallet{}
    |> insert_shared_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end
end
