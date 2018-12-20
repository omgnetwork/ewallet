defmodule EWallet.ActivityLogGate do
  @moduledoc """
  Handles the logic for manipulating activity logs.
  """
  import Ecto.Query
  alias EWalletDB.Repo
  alias EWallet.Web.Preloader
  alias ActivityLogger.ActivityLog

  @doc """
  Adds the originator and target struct for each activity log in the list.
  """
  def add_originator_and_target(activity_logs, overlay) when is_list(activity_logs) do
    activity_logs
    |> format_preload_values(overlay)
    |> query_preload(overlay)
    |> add_to_original(activity_logs)
  end

  # Extract and prepare data that need preloading in the following format
  # %{
  #   Entity1: [uuid1, uuid2, uuid3],
  #   Entity2: [uuid1, uuid2],
  #   ....
  # }
  defp format_preload_values(data, overlay) do
    Enum.reduce(data, %{}, fn activity_log, acc ->
      acc
      |> add_preload_if_valid(
        ActivityLog.get_schema(activity_log.originator_type),
        activity_log.originator_uuid,
        overlay
      )
      |> add_preload_if_valid(
        ActivityLog.get_schema(activity_log.target_type),
        activity_log.target_uuid,
        overlay
      )
    end)
  end

  # Checks if the given schema needs to be loaded.
  # If no -> do nothing
  # If yes -> adds an array of uuids for the given schema key
  defp add_preload_if_valid(preloads, schema, uuid, overlay) do
    case preloadable?(schema, overlay) do
      true ->
        preloads
        |> Map.put_new(schema, [])
        |> add_uuid_if_not_present(schema, uuid)

      false ->
        preloads
    end
  end

  # Adds the given uuid to the list for the schema if not already present
  defp add_uuid_if_not_present(preloads, schema, uuid) do
    uuids =
      case !Enum.member?(preloads[schema], uuid) do
        true -> [uuid | preloads[schema]]
        false -> preloads[schema]
      end

    Map.put(preloads, schema, uuids)
  end

  # Loops through the given preload map, loads the structs from the DB and format
  # them in the following format:
  # %{
  #   "entity_A": %{
  #     uuid1: %EntityA1{
  #       uuid: uuid1,
  #       key2: value2,
  #       ....
  #     },
  #     uuid2: %EntityA2{
  #       uuid: uuid2,
  #       key2: value2,
  #       ....
  #     }
  #   },
  #   "entity_B": %{
  #     uuid1: %EntityB1{
  #       uuid: uuid1,
  #       ...
  #     }, ...
  #   },
  #   ...
  # }
  defp query_preload(preloads, overlay) do
    Enum.reduce(preloads, %{}, fn {module, uuids}, acc ->
      module
      |> query_for_module(uuids, overlay)
      |> format_and_append_query_result(acc, module)
    end)
  end

  # Queries the results and their default preloaded associations for the given uuids
  defp query_for_module(module, uuids, overlay) do
    default_preload_assocs =
      module
      |> overlay.overlay_for_module()
      |> apply(:default_preload_assocs, [])

    query =
      from(
        s in module,
        where: s.uuid in ^uuids
      )

    query
    |> Repo.all()
    |> Preloader.preload_all(default_preload_assocs)
  end

  # Takes a successful tuple of results and format it into a map with the uuid as a key
  defp format_and_append_query_result({:ok, results}, acc, module) do
    formatted_result = Enum.into(results, %{}, &{&1.uuid, &1})
    Map.put(acc, ActivityLog.get_type(module), formatted_result)
  end

  defp format_and_append_query_result({:error, _}, acc, _), do: acc

  # Loops through the original list of activity logs and adds :originator and
  # :target keys for each log
  defp add_to_original(preloads, activity_logs) do
    Enum.map(activity_logs, fn activity_log ->
      value = preloads[activity_log.originator_type][activity_log.originator_uuid]
      activity_log = Map.put(activity_log, :originator, value)
      value = preloads[activity_log.target_type][activity_log.target_uuid]
      Map.put(activity_log, :target, value)
    end)
  end

  defp preloadable?(schema, overlay), do: overlay.overlay_for_module(schema) != nil
end
