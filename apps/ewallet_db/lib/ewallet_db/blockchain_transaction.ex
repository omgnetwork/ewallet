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

defmodule EWalletDB.BlockchainTransaction do
  @moduledoc """
  Ecto Schema representing blockchain transactions.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  import EWalletDB.{Validator, BlockchainValidator}
  alias Ecto.UUID
  alias EWalletDB.{BlockchainTransactionState, Repo}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_transaction" do
    field(:hash, :string)
    field(:rootchain_identifier, :string)
    field(:childchain_identifier, :string)
    field(:status, :string, default: BlockchainTransactionState.submitted())
    field(:block_number, :integer)
    field(:confirmed_at_block_number, :integer)
    field(:gas_price, Utils.Types.Integer)
    field(:gas_limit, Utils.Types.Integer)
    field(:error, :string)
    field(:metadata, :map, default: %{})

    timestamps()
    activity_logging()
  end

  defp shared_insert_changeset(%__MODULE__{} = blockchain_transaction, attrs) do
    blockchain_transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :hash,
        :rootchain_identifier,
        :status,
        :metadata
      ],
      required: [
        :hash,
        :rootchain_identifier,
        :status
      ]
    )
    |> validate_inclusion(:status, BlockchainTransactionState.statuses())
    |> validate_immutable(:hash)
    |> validate_immutable(:rootchain_identifier)
    |> validate_blockchain_identifier(:rootchain_identifier)
    |> unique_constraint(:hash)
  end

  defp rootchain_outgoing_insert_changeset(%__MODULE__{} = blockchain_transaction, attrs) do
    blockchain_transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:gas_price, :gas_limit],
      required: [:gas_price, :gas_limit]
    )
    |> validate_immutable(:gas_price)
    |> validate_immutable(:gas_limit)
    |> merge(shared_insert_changeset(blockchain_transaction, attrs))
  end

  defp rootchain_incoming_insert_changeset(%__MODULE__{} = blockchain_transaction, attrs) do
    blockchain_transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :block_number
      ]
    )
    |> validate_immutable(:block_number)
    |> merge(shared_insert_changeset(blockchain_transaction, attrs))
  end

  defp childchain_insert_changeset(%__MODULE__{} = blockchain_transaction, attrs) do
    blockchain_transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:childchain_identifier],
      required: [:childchain_identifier]
    )
    |> validate_immutable(:childchain_identifier)
    |> validate_blockchain_identifier(:childchain_identifier)
    |> merge(shared_insert_changeset(blockchain_transaction, attrs))
  end

  def state_changeset(
        %__MODULE__{} = blockchain_transaction,
        attrs,
        cast_fields,
        required_fields
      ) do
    blockchain_transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: cast_fields,
      required: required_fields
    )
    |> validate_inclusion(:status, BlockchainTransactionState.statuses())
    |> validate_immutable(:block_number)
    |> validate_immutable(:rootchain_identifier)
    |> validate_immutable(:childchain_identifier)
    |> validate_immutable(:confirmed_at_block_number)
    |> validate_immutable(:gas_price)
    |> validate_immutable(:gas_limit)
    |> validate_immutable(:hash)
  end

  def get_last_block_number(rootchain_identifier) do
    __MODULE__
    |> where([t], t.rootchain_identifier == ^rootchain_identifier and not is_nil(t.block_number))
    |> order_by([t], desc: t.block_number)
    |> select([t], t.block_number)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Inserts an outgoing rootchain transaction.
  """
  def insert_outgoing_rootchain(attrs) do
    %__MODULE__{}
    |> rootchain_outgoing_insert_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Inserts an incoming rootchain transaction.
  """
  def insert_incoming_rootchain(attrs) do
    %__MODULE__{}
    |> rootchain_incoming_insert_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Inserts a childchain transaction.
  """
  def insert_childchain(attrs) do
    %__MODULE__{}
    |> childchain_insert_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Retrieves a blockchain transaction using one or more fields.
  """
  @spec get_by(fields :: map() | keyword(), opts :: keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end
end
