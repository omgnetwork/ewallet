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

defmodule EWallet.Web.V1.ExportSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.ExportSerializer
  alias Utils.Helpers.{Assoc, DateFormatter}

  describe "serialize/1 for a single export" do
    test "serializes into correct V1 export format" do
      export = build(:export)

      expected = %{
        object: "export",
        id: export.id,
        filename: export.filename,
        schema: export.schema,
        status: export.status,
        completion: export.completion,
        download_url: export.url,
        adapter: export.adapter,
        user_id: Assoc.get(export, [:user, :id]),
        key_id: Assoc.get(export, [:key, :id]),
        params: export.params,
        pid: export.pid,
        failure_reason: nil,
        created_at: DateFormatter.to_iso8601(export.inserted_at),
        updated_at: DateFormatter.to_iso8601(export.updated_at)
      }

      assert ExportSerializer.serialize(export) == expected
    end

    test "serializes to nil if the export is not loaded" do
      assert ExportSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes nil to nil" do
      assert ExportSerializer.serialize(nil) == nil
    end
  end

  describe "serialize/1 for an export list" do
    test "serialize into list of V1 export" do
      export_1 = build(:export)
      export_2 = build(:export)

      paginator = %Paginator{
        data: [export_1, export_2],
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
            object: "export",
            id: export_1.id,
            filename: export_1.filename,
            schema: export_1.schema,
            status: export_1.status,
            completion: export_1.completion,
            download_url: export_1.url,
            adapter: export_1.adapter,
            user_id: Assoc.get(export_1, [:user, :id]),
            key_id: Assoc.get(export_1, [:key, :id]),
            params: export_1.params,
            pid: export_1.pid,
            failure_reason: nil,
            created_at: DateFormatter.to_iso8601(export_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(export_1.updated_at)
          },
          %{
            object: "export",
            id: export_2.id,
            filename: export_2.filename,
            schema: export_2.schema,
            status: export_2.status,
            completion: export_2.completion,
            download_url: export_2.url,
            adapter: export_2.adapter,
            user_id: Assoc.get(export_2, [:user, :id]),
            key_id: Assoc.get(export_2, [:key, :id]),
            params: export_2.params,
            pid: export_2.pid,
            failure_reason: nil,
            created_at: DateFormatter.to_iso8601(export_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(export_2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert ExportSerializer.serialize(paginator) == expected
    end
  end
end
