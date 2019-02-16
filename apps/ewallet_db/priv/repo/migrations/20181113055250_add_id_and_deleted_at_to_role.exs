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

defmodule EWalletDB.Repo.Migrations.AddIdAndDeletedAtToRole do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo
  alias ExULID.ULID

  def up do
    alter table(:role) do
      add :id, :string
      add :deleted_at, :naive_datetime_usec
    end

    create index(:role, [:id])
    create index(:role, [:deleted_at])

    flush()
    populate_id()
  end

  def down do
    alter table(:role) do
      remove :id
      remove :deleted_at
    end
  end

  # Helper functions

  defp populate_id do
    query = from(a in "role",
                 select: [a.uuid, a.inserted_at],
                 lock: "FOR UPDATE")

    for [uuid, inserted_at] <- Repo.all(query) do
      {date, {hours, minutes, seconds, microseconds}} = inserted_at

      {:ok, datetime} = NaiveDateTime.from_erl({date, {hours, minutes, seconds}}, {microseconds, 4})
      {:ok, datetime} = DateTime.from_naive(datetime, "Etc/UTC")

      ulid =
        datetime
        |> DateTime.to_unix(:millisecond)
        |> ULID.generate()
        |> String.downcase()

      id = "rol_" <> ulid

      query = from(r in "role",
                  where: r.uuid == ^uuid,
                  update: [set: [id: ^id]])

      Repo.update_all(query, [])
    end
  end
end
