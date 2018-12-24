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

defmodule EWallet.Web.V1.ActivityLogSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.ActivityLogSerializer

  describe "ActivityLogSerializer.serialize/1" do
    test "serializes an activity_log into V1 response format" do
      user = insert(:user)

      activity_log =
        :activity_log
        |> insert(%{originator_type: "user", originator_uuid: user.uuid})
        |> Map.put(:originator, user)
        |> Map.put(:target, nil)

      expected = %{
        action: activity_log.action,
        created_at: Date.to_iso8601(activity_log.inserted_at),
        id: activity_log.id,
        metadata: activity_log.metadata,
        object: "activity_log",
        originator: %{
          avatar: %{
            original: nil,
            large: nil,
            small: nil,
            thumb: nil
          },
          calling_name: user.calling_name,
          created_at: Date.to_iso8601(user.inserted_at),
          email: user.email,
          enabled: user.enabled,
          encrypted_metadata: user.encrypted_metadata,
          full_name: user.full_name,
          id: user.id,
          metadata: user.metadata,
          object: "user",
          provider_user_id: user.provider_user_id,
          socket_topic: "user:#{user.id}",
          updated_at: Date.to_iso8601(user.updated_at),
          username: user.username
        },
        originator_identifier: nil,
        originator_type: "user",
        target: nil,
        target_changes: activity_log.target_changes,
        target_encrypted_changes: activity_log.target_encrypted_changes,
        target_identifier: nil,
        target_type: "system"
      }

      assert ActivityLogSerializer.serialize(activity_log) == expected
    end

    test "serializes an activity_log paginator into a list object" do
      activity_log1 =
        :activity_log
        |> insert()
        |> Map.put(:originator, nil)
        |> Map.put(:target, nil)

      activity_log2 =
        :activity_log
        |> insert()
        |> Map.put(:originator, nil)
        |> Map.put(:target, nil)

      paginator = %Paginator{
        data: [activity_log1, activity_log2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            action: activity_log1.action,
            # to check
            created_at: Date.to_iso8601(activity_log1.inserted_at),
            id: activity_log1.id,
            metadata: activity_log1.metadata,
            object: "activity_log",
            originator: nil,
            originator_identifier: nil,
            originator_type: "system",
            target: nil,
            target_changes: activity_log1.target_changes,
            target_encrypted_changes: activity_log1.target_encrypted_changes,
            target_identifier: nil,
            target_type: "system"
          },
          %{
            action: activity_log2.action,
            # to check
            created_at: Date.to_iso8601(activity_log2.inserted_at),
            id: activity_log2.id,
            metadata: activity_log2.metadata,
            object: "activity_log",
            originator: nil,
            originator_identifier: nil,
            originator_type: "system",
            target: nil,
            target_changes: activity_log2.target_changes,
            target_encrypted_changes: activity_log2.target_encrypted_changes,
            target_identifier: nil,
            target_type: "system"
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert ActivityLogSerializer.serialize(paginator) == expected
    end

    test "serializes to nil if activity_log is not given" do
      assert ActivityLogSerializer.serialize(nil) == nil
    end

    test "serializes to nil if activity_log is not loaded" do
      assert ActivityLogSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes an empty activity_log paginator into a list object" do
      paginator = %Paginator{
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert ActivityLogSerializer.serialize(paginator) == expected
    end
  end

  describe "ActivityLogSerializer.serialize/2" do
    test "serializes activity_logs to ids" do
      activity_logs = [activity_log1, activity_log2] = insert_list(2, :account)

      assert ActivityLogSerializer.serialize(activity_logs, :id) == [
               activity_log1.id,
               activity_log2.id
             ]
    end
  end
end
