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

defmodule EWalletDB.Repo.Migrations.ChangeSubunitToUnitToDecimalInMintedTokens do
  use Ecto.Migration

  def up do
    alter table(:minted_token) do
      remove :subunit_to_unit
      add :subunit_to_unit, :decimal, precision: 81, scale: 0, null: false
    end
  end

  def down do
    alter table(:minted_token) do
      remove :subunit_to_unit
      add :subunit_to_unit, :integer, null: false
    end
  end
end
