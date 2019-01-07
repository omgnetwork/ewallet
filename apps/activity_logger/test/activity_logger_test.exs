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

defmodule ActivityLoggerTest do
  use ExUnit.Case, async: false

  describe "configure/1" do
    test "appends the config's activity log <-> schemas mapping with the given map" do
      _ =
        ActivityLogger.configure(%{
          ActivityLoggerTest => %{type: "activity_logger_test", identifier: nil}
        })

      schemas_to_activity_log =
        Application.get_env(:activity_logger, :schemas_to_activity_log_config)

      activity_log_types_to_schemas =
        Application.get_env(:activity_logger, :activity_log_types_to_schemas)

      assert Map.get(schemas_to_activity_log, ActivityLoggerTest) == %{
               identifier: nil,
               type: "activity_logger_test"
             }

      assert Map.get(activity_log_types_to_schemas, "activity_logger_test") == ActivityLoggerTest
    end
  end
end
