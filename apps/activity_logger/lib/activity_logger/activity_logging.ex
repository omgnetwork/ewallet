defmodule ActivityLogger.ActivityLogging do
  @moduledoc """
  Allows activity_log for Ecto records.
  """
  import Ecto.Changeset
  alias ActivityLogger.ActivityLog
  alias Utils.Types.VirtualStruct

  @doc false
  defmacro __using__(_) do
    quote do
      import ActivityLogger.ActivityLogging
      alias ActivityLogger.ActivityLogging
    end
  end

  @doc """
  A macro that adds the `:originator` virtual field to a schema.
  """
  defmacro activity_logging do
    quote do
      field(:originator, VirtualStruct, virtual: true)
    end
  end

  @doc """
  Prepares a changeset for activity_log.
  """
  def cast_and_validate_required_for_activity_log(record, attrs, opts \\ []) do
    record
    |> Map.delete(:originator)
    |> cast(attrs, [:originator | opts[:cast] || []])
    |> validate_required([:originator | opts[:required] || []])
    |> put_encrypted_changes(opts[:encrypted] || [])
    |> put_change(:prevent_saving, opts[:prevent_saving] || [])
  end

  def insert_log(action, changeset, record) do
    ActivityLog.insert(action, changeset, record)
  end

  defp put_encrypted_changes(changeset, []), do: changeset

  defp put_encrypted_changes(changeset, encrypted_fields) when is_list(encrypted_fields) do
    {changeset, encrypted_changes} =
      Enum.reduce(encrypted_fields, {changeset, %{}}, fn encrypted_field, {changeset, map} ->
        {
          changeset,
          Map.put(map, encrypted_field, get_change(changeset, encrypted_field))
        }
      end)

    changeset
    |> put_change(:encrypted_fields, encrypted_fields)
    |> put_change(:encrypted_changes, encrypted_changes)
  end

  defp put_encrypted_changes(changeset, _), do: changeset
end
