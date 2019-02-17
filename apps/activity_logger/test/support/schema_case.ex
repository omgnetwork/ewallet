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

defmodule ActivityLogger.SchemaCase do
  @moduledoc """
  This module defines common behaviors shared for ActivityLogger schema tests.

  Note that all macros below are quoted at `test ... do ... end` level
  with macro names starting with `test_`. This is so that in test cases,
  when these macros are used, they still resemble the original code.

  ## Example

  ### Original code:

  ```
  describe "SomeSchema.insert/1" do
    test "generates a UUID for SomeSchema" do
      # ...
      # lots of test code here
      # ...
    end

    test "generates inserted_at and updated_at values" do
      # ...
      # lots of test code here
      # ...
    end
  end
  ```

  ### Using macro:

  ```
  describe "SomeSchema.insert/1" do
    test_insert_generate_uuid SomeSchema
    test_insert_generate_timestamps SomeSchema
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import ActivityLogger.{Factory, SchemaCase}
      alias Ecto.Adapters.SQL
      alias Ecto.Adapters.SQL.Sandbox
      alias ActivityLogger.Repo

      setup do
        Sandbox.checkout(ActivityLogger.Repo)
      end
    end
  end

  @doc """
  Test schema's factory produces params that can be inserted successfully.
  """
  defmacro test_has_valid_factory(schema) do
    quote do
      test "produces valid params and inserts successfully" do
        schema = unquote(schema)

        {res, val} =
          schema
          |> get_factory
          |> params_for
          |> schema.insert()

        assert res == :ok
      end
    end
  end
end
