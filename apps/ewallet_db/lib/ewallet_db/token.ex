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

defmodule EWalletDB.Token do
  @moduledoc """
  Ecto Schema representing tokens.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{Account, Repo, Token}
  alias ExULID.ULID

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "token" do
    # tok_eur_01cbebcdjprhpbzp1pt7h0nzvt
    field(:id, :string)

    # "eur"
    field(:symbol, :string)
    # "EUR"
    field(:iso_code, :string)
    # "Euro"
    field(:name, :string)
    # Official currency of the European Union
    field(:description, :string)
    # "€"
    field(:short_symbol, :string)
    # "Cent"
    field(:subunit, :string)
    # 100
    field(:subunit_to_unit, Utils.Types.Integer)
    # true
    field(:symbol_first, :boolean)
    # "&#x20AC;"
    field(:html_entity, :string)
    # "978"
    field(:iso_numeric, :string)
    # 1
    field(:smallest_denomination, :integer)
    # false
    field(:locked, :boolean)
    field(:avatar, EWalletDB.Uploaders.Avatar.Type)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletDB.Encrypted.Map, default: %{})

    field(:enabled, :boolean)

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
    activity_logging()
  end

  defp changeset(%Token{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :symbol,
        :iso_code,
        :name,
        :description,
        :short_symbol,
        :subunit,
        :subunit_to_unit,
        :symbol_first,
        :html_entity,
        :iso_numeric,
        :smallest_denomination,
        :locked,
        :account_uuid,
        :metadata,
        :encrypted_metadata
      ],
      required: [
        :symbol,
        :name,
        :subunit_to_unit,
        :account_uuid
      ],
      encrypted: [:encrypted_metadata]
    )
    |> validate_number(
      :subunit_to_unit,
      greater_than: 0,
      less_than_or_equal_to: 1_000_000_000_000_000_000
    )
    |> validate_immutable(:symbol)
    |> unique_constraint(:symbol)
    |> unique_constraint(:iso_code)
    |> unique_constraint(:name)
    |> unique_constraint(:short_symbol)
    |> unique_constraint(:iso_numeric)
    |> foreign_key_constraint(:account_uuid)
    |> assoc_constraint(:account)
    |> set_id(prefix: "tok_")
  end

  defp update_changeset(%Token{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :iso_code,
        :name,
        :description,
        :short_symbol,
        :symbol_first,
        :html_entity,
        :iso_numeric,
        :metadata,
        :encrypted_metadata
      ],
      required: [
        :name
      ],
      encrypted: [:encrypted_metadata]
    )
    |> unique_constraint(:iso_code)
    |> unique_constraint(:name)
    |> unique_constraint(:short_symbol)
    |> unique_constraint(:iso_numeric)
  end

  defp enable_changeset(%Token{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(attrs, cast: [:enabled], required: [:enabled])
  end

  defp set_id(changeset, opts) do
    case get_field(changeset, :id) do
      nil ->
        symbol = get_field(changeset, :symbol)
        ulid = ULID.generate() |> String.downcase()
        put_change(changeset, :id, build_id(symbol, ulid, opts))

      _ ->
        changeset
    end
  end

  defp build_id(symbol, ulid, opts) do
    case opts[:prefix] do
      nil ->
        "#{symbol}_#{ulid}"

      prefix ->
        "#{prefix}#{symbol}_#{ulid}"
    end
  end

  @doc """
  Returns all tokens in the system
  """
  def all do
    Repo.all(Token)
  end

  @spec avatar_changeset(Ecto.Changeset.t() | %Token{}, map()) ::
          Ecto.Changeset.t() | %Token{} | no_return()
  defp avatar_changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(attrs)
    |> cast_attachments(attrs, [:avatar])
  end

  @doc """
  Stores an avatar for the given token.
  """
  @spec store_avatar(%Token{}, map()) :: %Token{} | nil | no_return()
  def store_avatar(%Token{} = token, %{"originator" => originator} = attrs) do
    attrs =
      attrs["avatar"]
      |> case do
        "" -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end
      |> Map.put(:originator, originator)

    changeset = avatar_changeset(token, attrs)

    case Repo.update_record_with_activity_log(changeset) do
      {:ok, token} -> get(token.id)
      result -> result
    end
  end

  @doc """
  Create a new token with the passed attributes.
  """
  def insert(attrs) do
    changeset = changeset(%Token{}, attrs)

    case Repo.insert_record_with_activity_log(changeset) do
      {:ok, token} ->
        {:ok, get(token.id)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update an existing token with the passed attributes.
  """
  def update(token, attrs) do
    token
    |> update_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Retrieve a token by id.
  """
  @spec get_by(String.t(), opts :: keyword()) :: %Token{} | nil
  def get(id, opts \\ [])
  def get(nil, _), do: nil

  def get(id, opts) do
    get_by([id: id], opts)
  end

  @doc """
  Retrieves a token using one or more fields.
  """
  @spec get_by(fields :: map() | keyword(), opts :: keyword()) :: %Token{} | nil
  def get_by(fields, opts \\ []) do
    Token
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Retrieve a list of tokens by supplying a list of IDs.
  """
  def get_all(ids) do
    Repo.all(from(m in Token, where: m.id in ^ids))
  end

  @doc """
  Enables or disables a token.
  """
  def enable_or_disable(token, attrs) do
    token
    |> enable_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end
end
