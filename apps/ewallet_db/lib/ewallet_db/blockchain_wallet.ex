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
  import EWalletDB.{BlockchainValidator, Validator}
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
    field(:blockchain_identifier, :string)

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
        :type,
        :public_key,
        :blockchain_identifier
      ],
      required: [:address, :name, :type, :blockchain_identifier]
    )
    |> unique_constraint(:name)
    |> validate_blockchain()
    |> validate_inclusion(:type, @wallet_types)
    |> validate_length(:address, count: :bytes, max: 255)
    |> validate_length(:name, count: :bytes, max: 255)
    |> validate_length(:public_key, count: :bytes, max: 255)
  end

  defp insert_hot_changeset(%BlockchainWallet{} = wallet, attrs) do
    shared = insert_shared_changeset(wallet, attrs)

    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:public_key],
      required: [:public_key]
    )
    |> merge(shared)
    |> validate_inclusion(:type, [@hot])
    |> validate_length(:public_key, count: :bytes, max: 255)
  end

  defp insert_cold_changeset(%BlockchainWallet{} = wallet, attrs) do
    wallet
    |> insert_shared_changeset(attrs)
    |> validate_inclusion(:type, [@cold])
  end

  defp validate_blockchain(changeset) do
    changeset
    |> validate_blockchain_address(:address)
    |> validate_blockchain_identifier(:blockchain_identifer)
    |> unique_constraint(:address, name: :blockchain_wallet_blockchain_identifier_address_index)
    |> unique_constraint(:public_key,
      name: :blockchain_wallet_blockchain_identifier_public_key_index
    )
    |> validate_immutable(:address)
    |> validate_immutable(:public_key)
    |> validate_immutable(:blockchain_identifer)
  end

  def get_primary_hot_wallet(identifier) do
    :ewallet_db
    |> Application.get_env(:primary_hot_wallet)
    |> get(@hot, identifier)
  end

  @doc """
  Retrieves all hot wallets.
  """
  def get_all_hot(blockchain_identifier, query \\ __MODULE__) do
    query
    |> where([w], w.blockchain_identifier == ^blockchain_identifier and w.type == "hot")
    |> Repo.all()
  end

  @doc """
  Retrieves a blockchain wallet using its address.
  """
  @spec get(String.t(), String.t(), String.t()) :: %BlockchainWallet{} | nil | no_return()
  def get(nil, _, _), do: nil

  def get(address, type, blockchain_identifier) do
    get_by(%{address: address, type: type, blockchain_identifier: blockchain_identifier})
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
  def insert(attrs) do
    %BlockchainWallet{}
    |> insert_shared_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Create a new hot blockchain wallet with the passed attributes.
  """
  @spec insert_hot(map()) :: {:ok, %__MODULE__{}}
  def insert_hot(attrs) do
    %BlockchainWallet{}
    |> insert_hot_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Create a new cold blockchain wallet with the passed attributes.
  """
  @spec insert_cold(map()) :: {:ok, %__MODULE__{}}
  def insert_cold(attrs) do
    %BlockchainWallet{}
    |> insert_cold_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end
end
