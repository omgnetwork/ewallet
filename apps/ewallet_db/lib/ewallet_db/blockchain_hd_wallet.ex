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

defmodule EWalletDB.BlockchainHDWallet do
  @moduledoc """
  Ecto Schema representing a blockchain wallet.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator

  alias Ecto.UUID
  alias EWalletDB.{Repo, BlockchainHDWallet}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_hd_wallet" do
    field(:keychain_id, :string)
    field(:blockchain_identifier, :string)

    activity_logging()
    timestamps()
  end

  defp changeset(%BlockchainHDWallet{} = wallet, attrs) do
    wallet
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :uuid,
        :keychain_id,
        :blockchain_identifier
      ],
      required: [:keychain_id, :blockchain_identifier]
    )
    |> unique_constraint(:keychain_id)
    |> validate_immutable(:keychain_id)
  end

  def get_primary do
    BlockchainHDWallet
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Create a new blockchain wallet with the passed attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}}
  def insert(attrs) do
    case get_primary() do
      nil ->
        %BlockchainHDWallet{}
        |> changeset(attrs)
        |> Repo.insert_record_with_activity_log()

      _ ->
        {:error, :blockchain_hd_wallet_already_exists}
    end
  end
end
