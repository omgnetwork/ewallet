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

# TODO: handled mintable tokens (locked)
# - Add ability to finish minting and toggle `locked` when done
# - Add ability to mint token on blockchain if not `locked`

# TODO: Add listener to change status from `pending` to `confirmed`
# after X block confirmation + balance > 0 for hot wallet

defmodule EWalletDB.Token.Blockchain do
  @moduledoc """
  An extension of Token for blockchain related functions.
  """
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.{BlockchainValidator, Validator}
  alias EWalletDB.{Repo, Token}

  @status_pending "pending"
  @status_confirmed "confirmed"
  @statuses [@status_pending, @status_confirmed]

  def status_pending, do: @status_pending
  def status_confirmed, do: @status_confirmed

  defp insert_with_blockchain_address_changeset(%Token{} = token, attrs) do
    token
    |> blockchain_changeset(attrs)
    |> merge(Token.shared_insert_changeset(token, attrs))
  end

  defp insert_with_contract_deployed_changeset(%Token{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(attrs,
      cast: [:blockchain_transaction_uuid, :contract_uuid],
      required: [:blockchain_transaction_uuid, :contract_uuid]
    )
    |> assoc_constraint(:blockchain_transaction)
    |> foreign_key_constraint(:blockchain_transaction_uuid)
    |> merge(insert_with_blockchain_address_changeset(token, attrs))
  end

  defp blockchain_changeset(%Token{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(attrs,
      cast: [:blockchain_address, :blockchain_identifier],
      required: [:blockchain_address, :blockchain_identifier]
    )
    |> unique_constraint(:blockchain_address,
      name: :token_blockchain_identifier_blockchain_address_index
    )
    |> validate_blockchain()
    # Note: We validate before force downcasing
    |> update_change(:blockchain_address, &String.downcase/1)
    |> merge(blockchain_status_changeset(token, attrs))
  end

  defp blockchain_status_changeset(%Token{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(attrs,
      cast: [:blockchain_status],
      required: [:blockchain_status]
    )
    |> validate_inclusion(:blockchain_status, @statuses)
  end

  defp validate_blockchain(changeset) do
    changeset
    |> validate_blockchain_address(:blockchain_address)
    |> validate_blockchain_identifier(:blockchain_identifier)
    |> validate_immutable(:blockchain_address)
    |> validate_immutable(:blockchain_identifier)
    |> validate_inclusion(:blockchain_status, @statuses)
    |> validate_length(:blockchain_address, count: :bytes, max: 255)
  end

  @doc """
  Returns a list of Tokens that have a blockchain address for the specified identifier
  """
  @spec all_blockchain(Ecto.Queryable.t()) :: [%Token{}]
  def all_blockchain(identifier, query \\ Token) do
    identifier
    |> query_all_blockchain(query)
    |> Repo.all()
  end

  @doc """
  Returns a query of Tokens that have a blockchain address for the specified identifier
  """
  @spec query_all_blockchain(String.t(), Ecto.Queryable.t()) :: [%Token{}]
  def query_all_blockchain(identifier, query \\ Token) do
    where(query, [t], not is_nil(t.blockchain_address) and t.blockchain_identifier == ^identifier)
  end

  @doc """
  Returns a query of Tokens that have an address matching in the provided list for the specified identifier
  """
  @spec query_all_by_blockchain_addresses([String.t()], String.t(), Ecto.Queryable.t()) :: [
          Ecto.Queryable.t()
        ]
  def query_all_by_blockchain_addresses(addresses, identifier, query \\ Token) do
    where(
      query,
      [t],
      t.blockchain_address in ^addresses and t.blockchain_identifier == ^identifier
    )
  end

  @doc """
  Create a new token with a blockchain address from the passed attributes.
  This is used when a token is created on the eWallet with a reference to
  an existing blockchain token (not managed by the eWallet).
  """
  def insert_with_blockchain_address(attrs) do
    %Token{}
    |> insert_with_blockchain_address_changeset(attrs)
    |> Token.insert_with_changeset()
  end

  @doc """
  Creates a new token containing a reference to the blockchain transaction that created the token.
  This is used when the token is deployed and managed by the eWallet.
  """
  def insert_with_contract_deployed(attrs) do
    %Token{}
    |> insert_with_contract_deployed_changeset(attrs)
    |> Token.insert_with_changeset()
  end

  def set_blockchain_address(token, attrs) do
    token
    |> blockchain_changeset(attrs)
    |> Token.update_with_changeset()
  end
end
