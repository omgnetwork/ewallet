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

  schema "blockchain_wallet" do
    # Blockchain wallets don't have an external ID. Use `address` instead.
    field(:address, :string)
    field(:name, :string)
    field(:public_key, :string)
    field(:type, :string)

    activity_logging()
    timestamps()
  end

  defp changeset(%BlockchainWallet{} = wallet, attrs) do
    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :uuid,
        :address,
        :public_key,
        :name,
        :type
      ],
      required: [:address, :name, :public_key, :type]
    )
    |> unique_constraint(:address)
    |> unique_constraint(:name)
    |> unique_constraint(:public_key)
    |> validate_immutable(:address)
    |> validate_immutable(:public_key)
    |> validate_inclusion(:type, @wallet_types)
    |> validate_length(:address, count: :bytes, max: 255)
    |> validate_length(:name, count: :bytes, max: 255)
    |> validate_length(:public_key, count: :bytes, max: 255)
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
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end
end
