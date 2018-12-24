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

defmodule EWalletConfig.Repo.Migrations.AddSettings do
  use Ecto.Migration

  def change do
    create table(:setting, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :key, :string, null: false
      add :data, :map
      add :encrypted_data, :binary
      add :type, :string, null: false
      add :description, :string
      add :options, :map
      add :parent, :string
      add :parent_value, :string
      add :secret, :boolean, null: false, default: false
      add :position, :integer, null: false

      timestamps()
    end

    create unique_index(:setting, [:id])
    create unique_index(:setting, [:key])
  end
end
