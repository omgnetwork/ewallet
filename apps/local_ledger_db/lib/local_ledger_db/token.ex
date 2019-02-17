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

defmodule LocalLedgerDB.Token do
  @moduledoc """
  Ecto Schema representing tokens. Tokens are made up of an
  id (e.g. OMG) and the associated UUID in eWallet DB.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias LocalLedgerDB.{Entry, Repo, Token}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "token" do
    field(:id, :string)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, LocalLedgerDB.Encrypted.Map, default: %{})

    has_many(
      :entries,
      Entry,
      foreign_key: :token_id,
      references: :id
    )

    timestamps()
  end

  @doc """
  Validate the token attributes.
  """
  def changeset(%Token{} = token, attrs) do
    token
    |> cast(attrs, [:id, :metadata, :encrypted_metadata])
    |> validate_required([:id, :metadata, :encrypted_metadata])
    |> unique_constraint(:id)
  end

  @doc """
  Retrieve a token from the database using the specified id
  or insert a new one before returning it.
  """
  def get_or_insert(%{"id" => id} = attrs) do
    case get(id) do
      nil ->
        insert(attrs)

      token ->
        {:ok, token}
    end
  end

  @doc """
  Retrieve a token using the specified id.
  """
  @spec get(String.t()) :: Ecto.Schema.t() | nil | no_return()
  def get(id) do
    Repo.get_by(Token, id: id)
  end

  @doc """
  Create a new token with the passed attributes. With
  "on conflict: nothing", conflicts are ignored. No matter what, a fresh get
  query is made to get the current database record, be it the one inserted right
  before or one inserted by another concurrent process.
  """
  @spec insert(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert(%{"id" => id} = attrs) do
    changeset = Token.changeset(%Token{}, attrs)
    opts = [on_conflict: :nothing, conflict_target: :id]

    case Repo.insert(changeset, opts) do
      {:ok, _token} ->
        {:ok, get(id)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
