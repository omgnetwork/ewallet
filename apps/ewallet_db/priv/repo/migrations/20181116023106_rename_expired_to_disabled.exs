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

defmodule EWalletDB.Repo.Migrations.RenameExpiredToDisabled do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @key_table_name "key"
  @api_key_table_name "api_key"

  def up do
    rename table(:key), :expired, to: :enabled
    rename table(:api_key), :expired, to: :enabled
    alter table(:key) do
      modify :enabled, :boolean, default: true
    end
    alter table(:api_key) do
      modify :enabled, :boolean, default: true
    end

    flush()

    swap(@key_table_name, :up)
    swap(@api_key_table_name, :up)
  end

  def down do
    rename table(:key), :enabled, to: :expired
    rename table(:api_key), :enabled, to: :expired
    alter table(:key) do
      modify :expired, :boolean, default: false
    end
    alter table(:api_key) do
      modify :expired, :boolean, default: false
    end

    flush()

    swap(@key_table_name, :down)
    swap(@api_key_table_name, :down)
  end

  defp swap(table_name, :up) do
    query = from(k in table_name,
                 update: [set: [enabled: not k.enabled]])

    Repo.update_all(query, [])
  end

  defp swap(table_name, :down) do
    query = from(k in table_name,
                 update: [set: [expired: not k.expired]])

    Repo.update_all(query, [])
  end
end
