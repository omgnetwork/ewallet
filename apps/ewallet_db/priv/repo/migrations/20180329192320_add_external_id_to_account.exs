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

defmodule EWalletDB.Repo.Migrations.AddExternalIdToAccount do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo
  alias ExULID.ULID

  def up do
    alter table(:account) do
      add :external_id, :string
    end

    create index(:account, [:external_id])

    flush()
    populate_external_id()
  end

  def down do
    alter table(:account) do
      remove :external_id
    end
  end

  defp populate_external_id do
    query = from(a in "account",
                 select: [a.id, a.inserted_at],
                 lock: "FOR UPDATE")

    for [id, inserted_at] <- Repo.all(query) do
      {date, {hours, minutes, seconds, microseconds}} = inserted_at

      {:ok, datetime} = NaiveDateTime.from_erl({date, {hours, minutes, seconds}}, {microseconds, 4})
      {:ok, datetime} = DateTime.from_naive(datetime, "Etc/UTC")

      ulid =
        datetime
        |> DateTime.to_unix(:millisecond)
        |> ULID.generate()

      query = from(a in "account",
                  where: a.id == ^id,
                  update: [set: [external_id: ^ulid]])

      Repo.update_all(query, [])
    end
  end
end
