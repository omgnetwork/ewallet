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

defmodule ActivityLogger do
  @moduledoc """
  Documentation for ActivityLogger.
  """

  def configure(schemas_to_activity_log_config) do
    update_config(:schemas_to_activity_log_config, schemas_to_activity_log_config)

    update_config(
      :activity_log_types_to_schemas,
      to_activity_log_types(schemas_to_activity_log_config)
    )
  end

  defp to_activity_log_types(schemas_to_activity_log_config) do
    Enum.into(schemas_to_activity_log_config, %{}, fn {key, value} ->
      {value[:type], key}
    end)
  end

  defp update_config(name, config) do
    current = Application.get_env(:activity_logger, name, %{})
    Application.put_env(:activity_logger, name, Map.merge(current, config))
  end
end
