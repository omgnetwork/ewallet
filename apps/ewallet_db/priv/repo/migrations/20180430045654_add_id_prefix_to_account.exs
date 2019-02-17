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

defmodule EWalletDB.Repo.Migrations.AddIdPrefixToAccount do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @table_name "account"
  @prefix "acc_"

  def up do
    for [uuid, id] <- get_all(@table_name) do
      id
      |> add_prefix(@prefix)
      |> update_id(@table_name, uuid)
    end
  end

  def down do
    for [uuid, id] <- get_all(@table_name) do
      id
      |> remove_prefix(@prefix)
      |> update_id(@table_name, uuid)
    end
  end

  # Add the prefix only if the ID is 26 characters long (ULID's length).
  # The previous ID format is UUID which is 36 character in length with hyphens and 32 without.
  # So it's safe to assume that 26-char IDs are the new format is suffice.
  defp add_prefix(id, prefix) when byte_size(id) == 26 do
    prefix <> id
  end
  defp add_prefix(id, _prefix), do: id

  # Remove the prefix only if the ID starts with the prefix
  defp remove_prefix(id, prefix) do
    String.replace_prefix(id, prefix, "")
  end

  defp get_all(table_name) do
    query = from(t in table_name,
                 select: [t.uuid, t.id],
                 lock: "FOR UPDATE")

    Repo.all(query)
  end

  defp update_id(id, table_name, uuid) do
    query = from(t in table_name,
                 where: t.uuid == ^uuid,
                 update: [set: [id: ^id]])

    Repo.update_all(query, [])
  end
end
