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

defmodule EWalletDB.Repo.Migrations.AddUsedAtAndExpiresAtToForgetPasswordRequest do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:forget_password_request) do
      add :used_at, :naive_datetime
      add :expires_at, :naive_datetime
    end

    create index(:forget_password_request, [:enabled, :expires_at])
    flush()

    add_expires_at_to_existing_requests()
  end

  def down do
    expires_past_requests()

    alter table(:forget_password_request) do
      remove :used_at
      remove :expires_at
    end
  end

  # Private functions

  defp add_expires_at_to_existing_requests do
    query = from(f in "forget_password_request",
      update: [
        set: [
          expires_at: fragment("? + '10 minute'::INTERVAL", f.inserted_at)
        ]
      ]
    )

    Repo.update_all(query, [])
  end

  defp expires_past_requests do
    query = from(f in "forget_password_request",
      where: f.enabled == true,
      where: f.expires_at <= ^NaiveDateTime.utc_now(),
      update: [set: [enabled: false]]
    )

    Repo.update_all(query, [])
  end
end
