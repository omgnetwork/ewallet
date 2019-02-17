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

defmodule EWallet.Web.V1.ActivityLogSerializer do
  @moduledoc """
  Serializes activity_logs into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.{PaginatorSerializer, ModuleMapper}
  alias ActivityLogger.ActivityLog
  alias Utils.Helpers.DateFormatter

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
      originator_identifier: activity_log.originator_identifier,
      originator: serialize_for_schema(activity_log.originator),
      target_type: activity_log.target_type,
      target_identifier: activity_log.target_identifier,
      target: serialize_for_schema(activity_log.target),
      target_changes: activity_log.target_changes,
      target_encrypted_changes: activity_log.target_encrypted_changes,
      metadata: activity_log.metadata,
      created_at: DateFormatter.to_iso8601(activity_log.inserted_at)
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
    |> ModuleMapper.config_for_module()
    |> Map.fetch!(:serializer)
    |> apply(:serialize, [schema])
  end
end
