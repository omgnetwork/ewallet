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

defmodule EWalletDB.DepositTransaction do
  @moduledoc """
  Ecto Schema representing deposit transactions.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.{BlockchainValidator, Validator}
  alias Ecto.UUID

  alias EWalletDB.{
    BlockchainDepositWallet,
    Repo,
    Token,
    BlockchainTransaction,
    BlockchainTransactionState
  }

  @outgoing "outgoing"
  @incoming "incoming"
  @types [@outgoing, @incoming]

  def outgoing, do: @outgoing
  def incoming, do: @incoming

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  @unfinalized_statuses BlockchainTransactionState.unfinalized_statuses()

  schema "deposit_transaction" do
    external_id(prefix: "dtx_")

    # Transaction inforrmation

    field(:type, :string, default: @incoming)
    field(:amount, Utils.Types.Integer)

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :blockchain_transaction,
      BlockchainTransaction,
      foreign_key: :blockchain_transaction_uuid,
      references: :uuid,
      type: UUID
    )

    # Source addresses

    field(:from_blockchain_address, :string)

    belongs_to(
      :from_deposit_wallet,
      BlockchainDepositWallet,
      foreign_key: :from_deposit_wallet_address,
      references: :address,
      type: :string
    )

    # Destination addresses

    field(:to_blockchain_address, :string)

    belongs_to(
      :to_deposit_wallet,
      BlockchainDepositWallet,
      foreign_key: :to_deposit_wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
    activity_logging()
  end

  defp insert_changeset(%__MODULE__{} = transaction, attrs) do
    transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :type,
        :amount,
        :token_uuid,
        :blockchain_transaction_uuid,
        :to_blockchain_address,
        :from_blockchain_address,
        :to_deposit_wallet_address,
        :from_deposit_wallet_address
      ],
      required: [
        :type,
        :amount,
        :token_uuid
      ]
    )
    |> validate_required_exclusive([:from_blockchain_address, :from_deposit_wallet_address])
    |> validate_required_exclusive([:to_blockchain_address, :to_deposit_wallet_address])
    |> validate_number(:amount, less_than: 100_000_000_000_000_000_000_000_000_000_000_000)
    |> validate_inclusion(:type, @types)
    |> validate_blockchain_address(:from_blockchain_address)
    |> validate_blockchain_address(:to_blockchain_address)
    |> assoc_constraint(:token)
  end

  defp update_changeset(%__MODULE__{} = transaction, attrs) do
    transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:blockchain_transaction_uuid],
      required: []
    )
    |> validate_immutable(:blockchain_transaction_uuid)
  end

  @doc """
  Gets a deposit transaction.
  """
  @spec get(String.t()) :: %__MODULE__{} | nil
  @spec get(String.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Get a deposit transaction using one or more fields.
  """
  @spec get_by(keyword() | map(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    query = Repo.get_by(__MODULE__, fields)

    case opts[:preload] do
      nil -> query
      preload -> Repo.preload(query, preload)
    end
  end

  @doc """
  Inserts a deposit transaction with the provided attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %__MODULE__{}
    |> insert_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Updates a deposit transaction with the provided attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(deposit_transaction, attrs) do
    changeset = update_changeset(deposit_transaction, attrs)

    case Repo.update_record_with_activity_log(changeset) do
      {:ok, updated} ->
        {:ok, get(updated.id)}

      error ->
        error
    end
  end

  @doc """
  Retrieves all deposit transactions that match the provided attributes,
  and are not considered final on the blockchain yet.

  This is useful, for example, for calculating the spendable amount where
  `spendable_amount = blockchain_balance - unfinalized_transaction_amounts`.
  """
  @spec all_unfinalized_by(keyword() | map()) :: [%__MODULE__{}]
  def all_unfinalized_by(clauses) do
    __MODULE__
    |> where(^Enum.to_list(clauses))
    |> join(:inner, [dt], t in assoc(dt, :blockchain_transaction))
    |> where([_, t], t.status in @unfinalized_statuses)
    |> Repo.all()
  end
end
