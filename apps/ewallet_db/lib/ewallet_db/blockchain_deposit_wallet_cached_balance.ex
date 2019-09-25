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

defmodule EWalletDB.BlockchainDepositWalletCachedBalance do
  @moduledoc """
  An Ecto schema representing a blockchain deposit wallet's cached balance.

  Note that this cached balance may have some delay from the actual blockchain balance,
  as it takes some time to periodically synchronize the balances.

  With this sync delay, this cached balance must not be used to assume that transactions made
  on it will be successful. However, it is useful for computing across many balances without
  resorting to querying the blockchain balance one by one, e.g. comparing all balances to pick
  a number of largest balances to pool funds into a hot wallet.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator

  alias Ecto.UUID

  alias EWalletDB.{
    Repo,
    BlockchainDepositWalletCachedBalance,
    BlockchainDepositWallet,
    Token
  }

  alias ActivityLogger.System

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_deposit_wallet_cached_balance" do
    field(:amount, Utils.Types.Integer)
    field(:blockchain_identifier, :string)

    belongs_to(
      :blockchain_deposit_wallet,
      BlockchainDepositWallet,
      foreign_key: :blockchain_deposit_wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
      references: :uuid,
      type: UUID
    )

    activity_logging()
    timestamps()
  end

  defp changeset(%__MODULE__{} = wallet, attrs) do
    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :amount,
        :blockchain_deposit_wallet_address,
        :token_uuid,
        :blockchain_identifier
      ],
      required: [:amount, :blockchain_identifier, :blockchain_deposit_wallet_address, :token_uuid]
    )
    |> validate_immutable(:blockchain_deposit_wallet_address)
    |> validate_immutable(:token_uuid)
    |> assoc_constraint(:blockchain_deposit_wallet)
    |> assoc_constraint(:token)
  end

  @spec all_for_token(%Token{} | [%Token{}], String.t()) :: [%__MODULE__{}]
  def all_for_token(tokens, blockchain_identifier) do
    token_uuids =
      tokens
      |> List.wrap()
      |> Enum.map(fn t -> t.uuid end)

    BlockchainDepositWalletCachedBalance
    |> where([b], b.token_uuid in ^token_uuids)
    |> where([b], b.blockchain_identifier == ^blockchain_identifier)
    |> Repo.all()
  end

  def create_or_update_all(address, balances, blockchain_identifier) do
    Enum.map(balances, fn %{amount: amount, token: token} ->
      %BlockchainDepositWalletCachedBalance{}
      |> changeset(%{
        blockchain_deposit_wallet_address: address,
        token_uuid: token.uuid,
        amount: amount,
        blockchain_identifier: blockchain_identifier,
        originator: %System{}
      })
      |> Repo.insert(
        on_conflict: [set: [amount: amount]],
        conflict_target: [:blockchain_deposit_wallet_address, :blockchain_identifier, :token_uuid]
      )
    end)
  end
end
