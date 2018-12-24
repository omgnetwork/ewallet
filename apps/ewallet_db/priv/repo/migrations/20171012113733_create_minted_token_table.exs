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

defmodule EWalletDB.Repo.Migrations.CreateMintedTokenTable do
  use Ecto.Migration

  def change do
    create table(:minted_token, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :symbol, :string, null: false
      add :iso_code, :string
      add :name, :string, null: false
      add :description, :string
      add :short_symbol, :string
      add :subunit, :string
      add :subunit_to_unit, :integer, null: false
      add :symbol_first, :boolean, null: false, default: true
      add :html_entity, :string
      add :iso_numeric, :string
      add :smallest_denomination, :integer
      add :locked, :boolean, default: false

      timestamps()
    end

    create unique_index(:minted_token, [:symbol])
    create unique_index(:minted_token, [:iso_code])
    create unique_index(:minted_token, [:name])
    create unique_index(:minted_token, [:short_symbol])
    create unique_index(:minted_token, [:iso_numeric])
  end
end
