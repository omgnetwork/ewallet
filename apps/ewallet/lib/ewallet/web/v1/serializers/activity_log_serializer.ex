defmodule EWallet.Web.V1.ActivityLogSerializer do
  @moduledoc """
  Serializes activity_logs into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.{PaginatorSerializer, Overlay}
  alias ActivityLogger.ActivityLog
  alias Utils.Helpers.Assoc

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(activity_logs) when is_list(activity_logs) do
    %{
      object: "list",
      data: Enum.map(activity_logs, &serialize/1)
    }
  end

  def serialize(%ActivityLog{} = activity_log) do
    %{
      object: "activity_log",
      id: activity_log.id,
      action: activity_log.action,
      originator_type: activity_log.originator_type,
      originator_id: Assoc.get(activity_log, [:originator, :id]),
      originator: serialize_for_schema(activity_log.originator),
      target_type: activity_log.target_type,
      target_id: Assoc.get(activity_log, [:target, :id]),
      target: serialize_for_schema(activity_log.target),
      target_changes: activity_log.target_changes,
      target_encrypted_changes: activity_log.target_encrypted_changes,
      metadata: activity_log.metadata,
      created_at: Date.to_iso8601(activity_log.inserted_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(activity_logs, :id) when is_list(activity_logs) do
    Enum.map(activity_logs, fn activity_log -> activity_log.id end)
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil

  defp serialize_for_schema(nil), do: nil

  defp serialize_for_schema(schema) do
    schema.__struct__
    |> serializer_for_module()
    |> apply(:serialize, [schema])
  end

  defp serializer_for_module(module) do
    module
    |> Overlay.overlay_for_module()
    |> apply(:serializer, [])
  end
end
