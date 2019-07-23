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

defmodule EWalletDB.BlockchainDepositWallet do
  @moduledoc """
  Ecto Schema representing a blockchain deposit wallet.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  import EWalletDB.Helpers.Preloader

  alias Ecto.UUID
  alias EWalletDB.{Repo, BlockchainDepositWallet, BlockchainHDWallet, Wallet}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_deposit_wallet" do
    # Blockchain deposit wallets don't have an external ID. Use `address` instead.
    field(:address, :string)
    field(:public_key, :string)
    field(:path_ref, :integer)
    field(:blockchain_identifier, :string)

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :blockchain_hd_wallet,
      BlockchainHDWallet,
      foreign_key: :blockchain_hd_wallet_uuid,
      references: :uuid,
      type: UUID
    )

    activity_logging()
    timestamps()
  end

  defp changeset(%BlockchainDepositWallet{} = wallet, attrs) do
    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :address,
        :public_key,
        :wallet_address,
        :blockchain_hd_wallet_uuid,
        :blockchain_identifier
      ],
      required: [:address, :wallet_address, :blockchain_hd_wallet_uuid, :blockchain_identifier]
    )
    |> unique_constraint(:address)
    |> unique_constraint(:public_key)
    |> validate_immutable(:address)
    |> validate_immutable(:public_key)
    |> validate_length(:address, count: :bytes, max: 255)
    |> validate_length(:public_key, count: :bytes, max: 255)
    |> assoc_constraint(:blockchain_hd_wallet)
  end

  # TODO: Reduce scope?
  def all(blockchain_identifier) do
    BlockchainDepositWallet
    |> where([w], w.blockchain_identifier == ^blockchain_identifier)
    |> Repo.all()
  end

  @doc """
  Retrieves a blockchain wallet using its address.
  """
  @spec get(String.t(), String.t()) :: %BlockchainDepositWallet{} | nil | no_return()
  def get(nil, _), do: nil

  def get(address) do
    get_by(%{address: address})
  end

  def get_last_for(wallet) do
    BlockchainDepositWallet
    |> where([dw], dw.wallet_address == ^wallet.address)
    |> order_by([dw], desc: dw.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Retrieves a blockchain wallet using one or more fields.
  """
  @spec get_by(fields :: map() | keyword(), opts :: keyword()) ::
          %BlockchainDepositWallet{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    BlockchainDepositWallet
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Create a new blockchain wallet with the passed attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}}
  def insert(attrs) do
    %BlockchainDepositWallet{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end
end
