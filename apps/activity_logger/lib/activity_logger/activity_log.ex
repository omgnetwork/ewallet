defmodule ActivityLogger.ActivityLog do
  @moduledoc """
  Ecto Schema representing activity_logs.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  import Ecto.{Changeset, Query}
  alias Ecto.{Changeset, UUID}

  alias ActivityLogger.{
    ActivityLog,
    Repo
  }

  @primary_key {:uuid, UUID, autogenerate: true}
  @primary_key {:uuid, UUID, autogenerate: true}

  schema "activity_log" do
    external_id(prefix: "adt_")

    field(:action, :string)

    field(:target_type, :string)
    field(:target_uuid, UUID)
    field(:target_changes, :map)
    field(:target_encrypted_changes, ActivityLogger.Encrypted.Map, default: %{})

    field(:originator_uuid, UUID)
    field(:originator_type, :string)

    field(:metadata, :map, default: %{})

    field(:inserted_at, :naive_datetime)
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :action,
      :target_type,
      :target_uuid,
      :target_changes,
      :target_encrypted_changes,
      :originator_uuid,
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

  @spec get_schema(String.t()) :: Atom.t()
  def get_schema(type) do
    config = Application.get_env(:activity_logger, :activity_log_types_to_schemas)
    Map.fetch!(config, type)
  end

  @spec get_type(Atom.t()) :: String.t()
  def get_type(schema) do
    config = Application.get_env(:activity_logger, :schemas_to_activity_log_types)
    Map.fetch!(config, schema)
  end

  @spec all_for_target(map()) :: [%ActivityLog{}]
  def all_for_target(record) do
    all_for_target(record.__struct__, record.uuid)
  end

  @spec all_for_target(String.t(), UUID.t()) :: [%ActivityLog{}]
  def all_for_target(type, uuid) when is_binary(type) do
    ActivityLog
    |> where([a], a.target_type == ^type and a.target_uuid == ^uuid)
    |> Repo.all()
  end

  @spec all_for_target(Atom.t(), UUID.t()) :: [%ActivityLog{}]
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

  @spec get_initial_originator(map()) :: map()
  def get_initial_originator(record) do
    activity_log_type = get_type(record.__struct__)
    activity_log = ActivityLog.get_initial_activity_log(activity_log_type, record.uuid)
    originator_schema = ActivityLog.get_schema(activity_log.originator_type)

    case originator_schema do
      ActivityLogger.System ->
        %ActivityLogger.System{uuid: activity_log.originator_uuid}

      schema ->
        Repo.get(schema, activity_log.originator_uuid)
    end
  end

  def insert(action, changeset, record) do
    action
    |> build_attrs(changeset, record)
    |> handle_insert(action)
  end

  defp handle_insert(:no_changes, :insert), do: {:ok, nil}
  defp handle_insert(:no_changes, :update), do: {:ok, nil}

  defp handle_insert(attrs, _) do
    %ActivityLog{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp build_attrs(action, changeset, record) do
    with {:ok, originator} <- get_originator(changeset, record),
         originator_type <- get_type(originator.__struct__),
         target_type <- get_type(record.__struct__),
         changes <- Map.delete(changeset.changes, :originator),
         true <- action == :delete || changes != %{} || :no_changes,
         encrypted_changes <- changes[:encrypted_changes],
         changes <- Map.delete(changes, :encrypted_changes),
         encrypted_fields <- changes[:encrypted_fields],
         changes <- Map.delete(changes, :encrypted_fields),
         changes <- format_changes(changes, encrypted_fields) do
      %{
        action: Atom.to_string(action),
        target_type: target_type,
        target_uuid: record.uuid,
        target_changes: changes,
        target_encrypted_changes: encrypted_changes || %{},
        originator_uuid: originator.uuid,
        originator_type: originator_type,
        inserted_at: NaiveDateTime.utc_now()
      }
    else
      error -> error
    end
  end

  defp format_changes(changes, nil) do
    changes
    |> Enum.into(%{}, fn {field, value} ->
      format_change(field, value)
    end)
  end

  defp format_changes(changes, encrypted_fields) do
    changes
    |> Enum.filter(fn {key, value} ->
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
    {field, value}
  end

  defp format_value(%Changeset{} = value) do
    value.data.uuid
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
