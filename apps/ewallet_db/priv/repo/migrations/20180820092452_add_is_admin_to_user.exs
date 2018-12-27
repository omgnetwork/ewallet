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

defmodule EWalletDB.Repo.Migrations.AddIsAdminToUser do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:user) do
      add :is_admin, :boolean, default: false, null: false
    end

    flush()

    # Get users that have membership
    query = from(m in "membership", distinct: m.user_uuid, select: m.user_uuid)

    # Update those users with memberships with `is_admin: true`
    for user_uuid <- Repo.all(query) do
      update_query = from(u in "user",
                   where: u.uuid == ^user_uuid,
                   update: [set: [is_admin: true]])

      Repo.update_all(update_query, [])
    end
  end

  def down do
    alter table(:user) do
      remove :is_admin
    end
  end
end
