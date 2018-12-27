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

defmodule EWalletDB.Repo.Migrations.UpdateTokenIdToLowercase do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @table "token"

  def up do
    query = from(t in @table,
                 select: [t.uuid, t.id],
                 lock: "FOR UPDATE")

    for [uuid, id] <- Repo.all(query) do
      [prefix, symbol, ulid] = String.split(id, "_", parts: 3)
      new_id = prefix <> "_" <> symbol <> "_" <> String.downcase(ulid)

      query = from(t in @table,
                   where: t.uuid == ^uuid,
                   update: [set: [id: ^new_id]])

      Repo.update_all(query, [])
    end
  end

  def down do
    # Not converting the uppercase back because:
    # 1. We don't know which tokens had uppercases (tokens inserted before this migration),
    #    and which had lowercases (tokens created after this migration).
    # 2. The lowercased ID should still work.
    # 3. `up/0` can be called again without breaking.
  end
end
