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

defmodule EWalletDB.Repo.Migrations.AddConfigToTransactionRequest do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :require_confirmation, :boolean, null: false, default: false
      add :max_consumptions, :integer
      add :consumption_lifetime, :integer # milliseconds
      add :expiration_date, :naive_datetime_usec
      add :expired_at, :naive_datetime_usec
      add :expiration_reason, :string
      add :allow_amount_override, :boolean, default: true
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:transaction_request, [:metadata], using: "gin")
    create index(:transaction_request, [:encryption_version])
    create index(:transaction_request, [:expiration_date])
  end
end
