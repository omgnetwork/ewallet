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

defmodule LocalLedgerDB.Repo.Migrations.CreateBalances do
  use Ecto.Migration

  def change do
    create table(:balance, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :string, null: false
      add :metadata, :binary
      add :encryption_version, :binary
      timestamps()
    end

    create unique_index(:balance, [:address])
    create index(:balance, [:encryption_version])
  end
end
