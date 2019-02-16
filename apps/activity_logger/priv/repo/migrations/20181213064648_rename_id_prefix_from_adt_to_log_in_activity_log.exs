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

defmodule ActivityLogger.Repo.Migrations.RenameIdPrefixFromAdtToLogInActivityLog do
  use Ecto.Migration
  import Ecto.Query
  alias ActivityLogger.Repo

  @table_name "activity_log"
  @from_prefix "adt_"
  @to_prefix "log_"

  defp get_all(table_name) do
    query = from(t in table_name,
                 select: [t.uuid, t.id],
                 lock: "FOR UPDATE")

    Repo.all(query)
  end

  def up do
    for [uuid, id] <- get_all(@table_name) do
      id
      |> String.replace_prefix(@from_prefix, @to_prefix)
      |> update_id(@table_name, uuid)
    end
  end

  def down do
    for [uuid, id] <- get_all(@table_name) do
      id
      |> String.replace_prefix(@to_prefix, @from_prefix)
      |> update_id(@table_name, uuid)
    end
  end

  defp update_id(id, table_name, uuid) do
    query = from(t in table_name,
                 where: t.uuid == ^uuid,
                 update: [set: [id: ^id]])

    Repo.update_all(query, [])
  end
end
