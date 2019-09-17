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
  Ecto Schema representing transactions.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.{Validator, BlockchainValidator}
  alias Ecto.UUID

  alias EWalletDB.{
    BlockchainWallet,
    BlockchainDepositWallet,
    DepositTransaction,
    Repo,
    Token,
    TransactionState
  }

  @outgoing "outgoing"
  @incoming "incoming"
  @types [@outgoing, @incoming]
  def outgoing, do: @outgoing
  def incoming, do: @incoming

  # List of transaction statuses that already affect the blockchain balances,
  # but we consider them unfinalized and hence should not be spent.
  # Note that non-blockchain statuses like pending() are not included
  # since pending transactions do not yet affect the blockchain balance.
  @unfinalized_statuses [
    TransactionState.blockchain_submitted(),
    TransactionState.pending_confirmations(),
    TransactionState.blockchain_confirmed()
  ]

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "deposit_transaction" do
    external_id(prefix: "dtx_")

    field(:type, :string, default: @incoming)
    field(:amount, Utils.Types.Integer)
    field(:gas_price, Utils.Types.Integer)
    field(:gas_limit, Utils.Types.Integer)
    field(:status, :string, default: TransactionState.pending())
    field(:blockchain_tx_hash, :string)
    field(:blockchain_identifier, :string)
    field(:confirmations_count, :integer)
    field(:blk_number, :integer)
    field(:error_code, :string)
    field(:error_description, :string)
    field(:error_data, :map)

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :from_deposit_wallet,
      BlockchainDepositWallet,
      foreign_key: :from_deposit_wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :from_blockchain_wallet,
      BlockchainWallet,
      foreign_key: :from_blockchain_wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :to_deposit_wallet,
      BlockchainDepositWallet,
      foreign_key: :to_deposit_wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :to_blockchain_wallet,
      BlockchainWallet,
      foreign_key: :to_blockchain_wallet_address,
      references: :address,
      type: :string
    )

    timestamps()
    activity_logging()
  end

  defp insert_changeset(%DepositTransaction{} = transaction, attrs) do
    transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :status,
        :type,
        :token_uuid,
        :amount,
        :gas_price,
        :gas_limit,
        :to_blockchain_wallet_address,
        :from_blockchain_wallet_address,
        :to_deposit_wallet_address,
        :from_deposit_wallet_address,
        :blockchain_identifier,
        :blk_number,
        :error_code,
        :error_description,
        :confirmations_count
      ],
      required: [
        :status,
        :type,
        :token_uuid,
        :amount,
        :gas_price,
        :gas_limit,
        :blockchain_identifier
      ]
    )
    |> validate_required_exclusive([:from_blockchain_wallet_address, :from_deposit_wallet_address])
    |> validate_required_exclusive([:to_blockchain_wallet_address, :to_deposit_wallet_address])
    |> validate_number(:amount, less_than: 100_000_000_000_000_000_000_000_000_000_000_000)
    |> validate_number(:gas_price, greater_than: 0)
    |> validate_number(:gas_limit, greater_than: 0)
    |> validate_inclusion(:status, TransactionState.statuses())
    |> validate_inclusion(:type, @types)
    |> validate_immutable(:blockchain_tx_hash)
    |> validate_blockchain_address(:from_blockchain_address)
    |> validate_blockchain_address(:to_blockchain_address)
    |> validate_blockchain_identifier(:blockchain_identifier)
    |> unique_constraint(:unique_hash_constraint, name: :unique_hash_constraint)
    |> assoc_constraint(:token)
    |> assoc_constraint(:from_blockchain_wallet)
    |> assoc_constraint(:to_blockchain_wallet)
  end

  defp update_changeset(%DepositTransaction{} = transaction, attrs) do
    transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :blockchain_tx_hash,
        :blk_number,
        :error_code,
        :error_description,
        :confirmations_count
      ],
      required: []
    )
  end

  def state_changeset(%DepositTransaction{} = transaction, attrs, cast_fields, required_fields) do
    transaction
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: cast_fields,
      required: required_fields
    )
    |> validate_inclusion(:status, TransactionState.statuses())
  end

  def get_highest_blk_number(blockchain) do
    Transaction
    |> where([t], t.blockchain_identifier == ^blockchain and not is_nil(t.blk_number))
    |> order_by([t], desc: t.blk_number)
    |> select([t], t.blk_number)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Gets a transaction.
  """
  @spec get(String.t()) :: %DepositTransaction{} | nil
  @spec get(String.t(), keyword()) :: %DepositTransaction{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Get a transaction using one or more fields.
  """
  @spec get_by(keyword() | map(), keyword()) :: %DepositTransaction{} | nil
  def get_by(clauses, opts \\ []) do
    query = Repo.get_by(DepositTransaction, clauses)

    case opts[:preload] do
      nil -> query
      preload -> Repo.preload(query, preload)
    end
  end

  @doc """
  Inserts a transaction and ignores the conflicts on idempotency token, then retrieves the transaction
  using the passed idempotency token.
  """
  def insert(attrs) do
    %DepositTransaction{}
    |> insert_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Retrieves all deposit transactions from the given deposit address that are not yet finalized.

  This is useful for retrieving transactions that are happening and so to be excluded
  from the wallet's spendable balance.
  """
  @spec all_unfinalized_by(keyword() | map()) :: [%__MODULE__{}]
  def all_unfinalized_by(clauses) do
    DepositTransaction
    |> where(^Enum.to_list(clauses))
    |> where([dt], dt.status in @unfinalized_statuses)
    |> Repo.all()
  end

  def get_error(nil), do: nil

  def get_error(transaction) do
    {transaction.error_code, transaction.error_description || transaction.error_data}
  end

  def failed?(transaction) do
    transaction.status == TransactionState.failed()
  end
end
