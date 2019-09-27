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

  alias EWalletDB.{
    BlockchainDepositWallet,
    BlockchainDepositWalletCachedBalance,
    BlockchainHDWallet,
    Repo,
    Wallet
  }

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_deposit_wallet" do
    # Blockchain deposit wallets don't have an external ID. Use `address` instead.
    field(:address, :string)
    field(:relative_hd_path, :integer)
    field(:blockchain_identifier, :string)

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :blockchain_hd_wallet,
      BlockchainHDWallet,
      foreign_key: :blockchain_hd_wallet_uuid,
      references: :uuid,
      type: UUID
    )

    has_many(
      :cached_balances,
      BlockchainDepositWalletCachedBalance,
      foreign_key: :blockchain_deposit_wallet_address,
      references: :address
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
        :relative_hd_path,
        :blockchain_identifier,
        :wallet_uuid,
        :blockchain_hd_wallet_uuid
      ],
      required: [
        :address,
        :relative_hd_path,
        :blockchain_identifier,
        :wallet_uuid,
        :blockchain_hd_wallet_uuid
      ]
    )
    |> update_change(:address, &String.downcase/1)
    |> unique_constraint(:address)
    |> unique_constraint(:relative_hd_path,
      name: :blockchain_deposit_wallet_wallet_uuid_relative_hd_path_index
    )
    |> validate_immutable(:address)
    |> validate_immutable(:relative_hd_path)
    |> validate_length(:address, count: :bytes, max: 255)
    |> assoc_constraint(:wallet)
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
  @spec get(String.t()) :: %BlockchainDepositWallet{} | nil
  @spec get(String.t(), keyword()) :: %BlockchainDepositWallet{} | nil
  def get(address, opts \\ [])

  def get(nil, _), do: nil

  def get(address, opts) do
    get_by(%{address: address}, opts)
  end

  def get_last_for(wallet) do
    BlockchainDepositWallet
    |> where([dw], dw.wallet_uuid == ^wallet.uuid)
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

  @doc """
  Re-retrieve the balances from the database.
  """
  def reload_balances(deposit_wallet) do
    Repo.preload(deposit_wallet, :cached_balances, force: true)
  end
end
