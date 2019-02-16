# Copyright 2019 OmiseGO Pte Ltd
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

defmodule ActivityLogger.ActivityLoggingTest do
  use ExUnit.Case
  import ActivityLogger.Factory
  alias ActivityLogger.ActivityLogging
  alias ActivityLogger.TestDocument
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(ActivityLogger.Repo)

    attrs = %{
      title: "A title",
      body: "some body that we don't want to save",
      secret_data: %{something: "secret"},
      originator: insert(:test_user)
    }

    %{attrs: attrs}
  end

  describe "cast_and_validate_required_for_activity_log/3" do
    test "returns a valid changeset", meta do
      changeset =
        %TestDocument{}
        |> ActivityLogging.cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: [:title, :body, :secret_data],
          required: [:title],
          prevent_saving: [:body],
          encrypted: [:secret_data]
        )

      assert changeset.valid?
      assert changeset.changes.encrypted_fields == [:secret_data]
      assert changeset.changes.encrypted_changes == %{secret_data: %{something: "secret"}}
      assert changeset.changes.prevent_saving == [:body]
    end

    test "does not cast fields outside :cast opts", meta do
      changeset =
        %TestDocument{}
        |> ActivityLogging.cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: [:title]
        )

      assert Map.has_key?(changeset.changes, :title)
      refute Map.has_key?(changeset.changes, :body)
      refute Map.has_key?(changeset.changes, :secret_data)
    end

    test "invalidates the changeset if originator is not provided", meta do
      attrs = Map.put(meta.attrs, :originator, nil)

      changeset =
        ActivityLogging.cast_and_validate_required_for_activity_log(%TestDocument{}, attrs)

      refute changeset.valid?
      assert changeset.errors == [originator: {"can't be blank", [validation: :required]}]
    end

    test "invalidates the changeset if the required field is missing", meta do
      attrs = Map.put(meta.attrs, :title, nil)

      changeset =
        %TestDocument{}
        |> ActivityLogging.cast_and_validate_required_for_activity_log(
          attrs,
          cast: [:title],
          required: [:title]
        )

      refute changeset.valid?
      assert changeset.errors == [title: {"can't be blank", [validation: :required]}]
    end
  end
end
