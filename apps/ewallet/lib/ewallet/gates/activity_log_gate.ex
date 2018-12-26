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
  @spec add_originator_and_target([%ActivityLog{}], module()) :: [%ActivityLog{}]
  def add_originator_and_target(activity_logs, module_mapper) do
    activity_logs
    |> format_preload_values(module_mapper)
    |> query_preload(module_mapper)
    |> add_to_original(activity_logs)
  end

  # Extract and prepare data that need preloading in the following format
  # %{
  #   Entity1: [uuid1, uuid2, uuid3],
  #   Entity2: [uuid1, uuid2],
  #   ....
  # }
  defp format_preload_values(data, module_mapper) do
    Enum.reduce(data, %{}, fn activity_log, acc ->
      acc
      |> add_preload_if_valid(
        ActivityLog.get_schema(activity_log.originator_type),
        activity_log.originator_uuid,
        module_mapper
      )
      |> add_preload_if_valid(
        ActivityLog.get_schema(activity_log.target_type),
        activity_log.target_uuid,
        module_mapper
      )
    end)
  end

  # Checks if the given schema needs to be loaded.
  # If no -> do nothing
  # If yes -> adds an array of uuids for the given schema key
  defp add_preload_if_valid(preloads, schema, uuid, module_mapper) do
    case preloadable?(schema, module_mapper) do
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
  defp query_preload(preloads, module_mapper) do
    Enum.reduce(preloads, %{}, fn {module, uuids}, acc ->
      module
      |> query_for_module(uuids, module_mapper)
      |> format_and_append_query_result(acc, module)
    end)
  end

  # Queries the results and their default preloaded associations for the given uuids
  defp query_for_module(module, uuids, module_mapper) do
    default_preload_assocs =
      module
      |> module_mapper.config_for_module()
      |> Map.fetch!(:overlay)
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

  defp preloadable?(schema, module_mapper), do: module_mapper.config_for_module(schema) != nil
end
