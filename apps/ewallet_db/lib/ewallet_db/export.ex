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

defmodule EWalletDB.Export do
  @moduledoc """
  Ecto Schema representing audits.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import EWalletConfig.Validator
  import EWalletDB.Helpers.Preloader
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletConfig.Config

  alias EWalletDB.{
    Export,
    Repo,
    User,
    Key,
    Uploaders.File
  }

  @new "new"
  @processing "processing"
  @completed "completed"
  @failed "failed"

  def new, do: @new
  def processing, do: @processing
  def completed, do: @completed
  def failed, do: @failed

  @default_format "csv"
  @formats ["csv"]

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "export" do
    external_id(prefix: "exp_")

    field(:schema, :string)
    field(:format, :string, default: @default_format)
    field(:status, :string)
    # Completion is between 0 and 100
    field(:completion, :float)
    field(:url, :string)
    field(:filename, :string)
    field(:path, :string)
    field(:pid, :string)
    field(:failure_reason, :string)
    field(:full_error, :string)
    field(:estimated_size, :float)
    field(:total_count, :integer)
    field(:adapter, :string)
    field(:params, :map)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :key,
      Key,
      foreign_key: :key_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
    activity_logging()
  end

  defp create_changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :schema,
        :status,
        :format,
        :completion,
        :params,
        :user_uuid,
        :key_uuid
      ],
      required: [
        :schema,
        :status,
        :completion,
        :params
      ]
    )
    |> validate_required_exclusive([:user_uuid, :key_uuid])
    |> validate_number(:completion, greater_than_or_equal_to: 0)
    |> validate_number(:completion, less_than_or_equal_to: 100)
    |> validate_inclusion(:format, @formats)
    |> validate_inclusion(:status, [@new, @processing, @completed, @failed])
    |> assoc_constraint(:user)
    |> assoc_constraint(:key)
  end

  defp update_changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :status,
        :completion,
        :url,
        :path,
        :filename,
        :adapter,
        :schema,
        :total_count,
        :failure_reason,
        :estimated_size,
        :pid
      ],
      required: [
        :status,
        :completion
      ]
    )
    |> validate_number(:completion, greater_than_or_equal_to: 0)
    |> validate_number(:completion, less_than_or_equal_to: 100)
    |> validate_inclusion(:status, [@new, @processing, @completed, @failed])
  end

  @doc """
  Retrieves a list of all exports created by the given user.
  """
  def all_for(%User{} = user, storage_adapter, query) do
    from(e in query, where: e.user_uuid == ^user.uuid and e.adapter == ^storage_adapter)
  end

  @doc """
  Retrieves a list of all exports created by the given key.
  """
  def all_for(%Key{} = key, storage_adapter, query) do
    from(e in query, where: e.key_uuid == ^key.uuid and e.adapter == ^storage_adapter)
  end

  @doc """
  Retrieves an export with the given ID.
  """
  @spec get(String.t(), keyword()) :: %Export{} | nil | no_return()
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an export using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %Export{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    Export
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Initiates the given inserted export.
  """
  def init(export, schema, count, estimated_size, originator) do
    time = Timex.format!(export.inserted_at, "%Y-%m-%d_%H:%M:%S:%L", :strftime)
    filename = "#{schema}-#{time}.csv"

    Export.update(export, %{
      status: Export.processing(),
      completion: 1,
      path: "#{File.storage_dir(nil, nil)}/#{filename}",
      filename: filename,
      adapter: Config.get(:file_storage_adapter),
      schema: schema,
      total_count: count,
      estimated_size: estimated_size,
      originator: originator
    })
  end

  @doc """
  Inserts a new export.
  """
  @spec insert(map()) :: {:ok, %Export{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %Export{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the given export with the given attributes.
  """
  @spec update(%Export{}, map()) :: {:ok, %Export{}} | {:error, Ecto.Changeset.t()}
  def update(%Export{} = export, attrs) do
    export
    |> update_changeset(attrs)
    |> Repo.update()
  end
end
