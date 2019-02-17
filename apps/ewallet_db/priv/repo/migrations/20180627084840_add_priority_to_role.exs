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

defmodule EWalletDB.Repo.Migrations.AddPriorityToRole do
  use Ecto.Migration
  alias EWalletDB.Repo

  def change do
    alter table(:role) do
      add :priority, :integer
    end
    create unique_index(:role, [:priority])

    flush()

    {:ok, res} = Repo.query("SELECT uuid FROM role ORDER BY inserted_at")

    res.rows
    |> Enum.with_index
    |> Enum.each(fn({row, i}) ->
      {:ok, _} = Repo.query("UPDATE role SET priority = $1 WHERE uuid = $2", [i, Enum.at(row, 0)])
    end)

    flush()

    alter table(:role) do
      modify :priority, :integer, null: false
    end
  end
end
