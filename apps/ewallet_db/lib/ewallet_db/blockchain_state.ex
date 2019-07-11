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

defmodule EWalletDB.BlockchainState do
  @moduledoc """
  Ecto Schema representing a blockchain state.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{BlockchainState, Repo}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "blockchain_state" do
    field(:identifier, :string)
    field(:blk_number, :integer, default: 0)

    timestamps()
  end

  defp changeset(%BlockchainState{} = state, attrs) do
    state
    |> cast(attrs, [:identifier, :blk_number])
    |> validate_required([:identifier, :blk_number])
  end

  def get(id, queryable \\ BlockchainState)

  def get(identifier, queryable) when is_binary(identifier) do
    queryable
    |> Repo.get_by(identifier: identifier)
  end

  def get(_, _), do: nil

  def insert(attrs) do
    %BlockchainState{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def update(identifier, blk_number) when is_binary(identifier) do
    case get(identifier) do
      nil ->
        # TODO: better error
        {:error, :not_found}

      state ->
        state
        |> changeset(%{blk_number: blk_number})
        |> Repo.update()
    end
  end
end
