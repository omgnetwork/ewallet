# Copyright 2018 OmiseGO Pte Ltd
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

defmodule ActivityLogger.ActivityLog do
  @moduledoc """
  Ecto Schema representing activity_logs.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  import Ecto.{Changeset, Query}
  alias Ecto.{Changeset, UUID}
  alias Utils.Helpers.{Assoc, DateFormatter}

  alias ActivityLogger.{
    ActivityLog,
    Repo
  }

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "activity_log" do
    external_id(prefix: "log_")

    field(:action, :string)

    field(:target_type, :string)
    field(:target_uuid, UUID)
    field(:target_identifier, :string)
    field(:target_changes, :map)
    field(:target_encrypted_changes, ActivityLogger.Encrypted.Map, default: %{})

    field(:originator_uuid, UUID)
    field(:originator_type, :string)
    field(:originator_identifier, :string)

    field(:metadata, :map, default: %{})

    field(:inserted_at, :naive_datetime_usec)
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :action,
      :target_type,
      :target_uuid,
      :target_identifier,
      :target_changes,
      :target_encrypted_changes,
      :originator_uuid,
      :originator_identifier,
      :originator_type,
      :metadata,
      :inserted_at
    ])
    |> validate_required([
      :action,
      :target_type,
      :target_uuid,
      :target_changes,
      :originator_uuid,
      :originator_type,
      :inserted_at
    ])
  end

  @spec get_schema(String.t()) :: atom()
  def get_schema(type) do
    config = Application.get_env(:activity_logger, :activity_log_types_to_schemas)
    Map.fetch!(config, type)
  end

  @spec get_type(atom()) :: String.t()
  def get_type(schema) do
    :activity_logger
    |> Application.get_env(:schemas_to_activity_log_config)
    |> Map.fetch!(schema)
    |> Map.fetch!(:type)
  end

  @spec get_identifier(atom()) :: atom() | nil
  def get_identifier(schema) do
    :activity_logger
    |> Application.get_env(:schemas_to_activity_log_config)
    |> Map.fetch!(schema)
    |> Map.fetch!(:identifier)
  end

  @spec all_for_target(map()) :: [%ActivityLog{}]
  def all_for_target(record) do
    all_for_target(record.__struct__, record.uuid)
  end

  @spec all_for_target(String.t(), UUID.t()) :: [%ActivityLog{}]
  def all_for_target(type, uuid) when is_binary(type) do
    ActivityLog
    |> order_by(desc: :inserted_at)
    |> where([a], a.target_type == ^type and a.target_uuid == ^uuid)
    |> Repo.all()
  end

  @spec all_for_target(atom(), UUID.t()) :: [%ActivityLog{}]
  def all_for_target(schema, uuid) do
    schema
    |> get_type()
    |> all_for_target(uuid)
  end

  @spec get_initial_activity_log(String.t(), UUID.t()) :: %ActivityLog{}
  def get_initial_activity_log(type, uuid) do
    Repo.get_by(
      ActivityLog,
      action: "insert",
      target_type: type,
      target_uuid: uuid
    )
  end

  @doc """
  Returns the initial originator, a.k.a. the originator that inserted
  the given record to the database.

  In a transactional operation, e.g. during tests, where the insert
  maybe happening in another repo such as `EWalletDB.Repo`, the record
  may not be visible to this function yet. In a scenario like this,
  you can dependency-inject the visible repo via `repo`.
  """
  @spec get_initial_originator(map(), module()) :: map()
  def get_initial_originator(record, repo \\ Repo) do
    activity_log_type = get_type(record.__struct__)
    activity_log = ActivityLog.get_initial_activity_log(activity_log_type, record.uuid)
    originator_schema = ActivityLog.get_schema(activity_log.originator_type)

    case originator_schema do
      ActivityLogger.System ->
        %ActivityLogger.System{uuid: activity_log.originator_uuid}

      schema ->
        repo.get(schema, activity_log.originator_uuid)
    end
  end

  def insert(action, changeset, record) do
    action
    |> build_attrs(changeset, record)
    |> handle_insert(action)
  end

  defp build_attrs(action, changeset, record) do
    with {:ok, originator} <- get_originator(changeset, record),
         originator_type <- get_type(originator.__struct__),
         target_type <- get_type(record.__struct__),
         changes <- Map.delete(changeset.changes, :originator),
         encrypted_changes <- changes[:encrypted_changes],
         changes <- Map.delete(changes, :encrypted_changes),
         encrypted_fields <- changes[:encrypted_fields],
         changes <- Map.delete(changes, :encrypted_fields),
         prevent_saving <- changes[:prevent_saving],
         changes <- Map.delete(changes, :prevent_saving),
         changes <- format_changes(changes, encrypted_fields),
         changes <- remove_forbidden(changes, prevent_saving),
         encrypted_changes <- remove_forbidden(encrypted_changes, prevent_saving),
         true <-
           action == :delete || has_changes?(changes) || has_changes?(encrypted_changes) ||
             :no_changes do
      %{
        action: Atom.to_string(action),
        target_type: target_type,
        target_uuid: record.uuid,
        target_identifier: Assoc.get_if_exists(record, [get_identifier(record.__struct__)]),
        target_changes: changes,
        target_encrypted_changes: encrypted_changes || %{},
        originator_uuid: originator.uuid,
        originator_identifier:
          Assoc.get_if_exists(originator, [get_identifier(originator.__struct__)]),
        originator_type: originator_type,
        inserted_at: NaiveDateTime.utc_now()
      }
    else
      error -> error
    end
  end

  defp has_changes?(changes) when is_map(changes) and map_size(changes) > 0, do: true
  defp has_changes?(_), do: false

  defp handle_insert(:no_changes, :insert), do: {:ok, nil}
  defp handle_insert(:no_changes, :update), do: {:ok, nil}

  defp handle_insert(attrs, _) do
    %ActivityLog{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp remove_forbidden(changes, nil), do: changes
  defp remove_forbidden(nil, _), do: nil

  defp remove_forbidden(changes, prevent_saving) do
    changes
    |> Enum.filter(fn {key, _} -> !Enum.member?(prevent_saving, key) end)
    |> Enum.into(%{})
  end

  defp format_changes(changes, nil) do
    changes
    |> Enum.into(%{}, fn {field, value} ->
      format_change(field, value)
    end)
  end

  defp format_changes(changes, encrypted_fields) do
    changes
    |> Enum.filter(fn {key, _} ->
      !Enum.member?(encrypted_fields, key)
    end)
    |> format_changes(nil)
  end

  defp format_change(field, values) when is_list(values) do
    {field,
     Enum.map(values, fn value ->
       format_value(value)
     end)}
  end

  defp format_change(field, value) do
    {field, format_value(value)}
  end

  defp format_value(%Changeset{} = value) do
    value.data.uuid
  end

  defp format_value(%DateTime{} = value) do
    DateFormatter.to_iso8601(value)
  end

  defp format_value(%NaiveDateTime{} = value) do
    DateFormatter.to_iso8601(value)
  end

  defp format_value(values) when is_map(values) do
    Enum.into(values, %{}, fn {key, value} ->
      {key, format_value(value)}
    end)
  end

  defp format_value(value), do: value

  defp get_originator(%Changeset{changes: %{originator: :self}}, record) do
    {:ok, record}
  end

  defp get_originator(%Changeset{changes: %{originator: originator}}, _) do
    {:ok, originator}
  end

  defp get_originator(_, _) do
    {:error, :no_originator_given}
  end
end
