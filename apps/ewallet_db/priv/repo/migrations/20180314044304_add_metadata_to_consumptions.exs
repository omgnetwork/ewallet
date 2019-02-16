# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.Repo.Migrations.AddMetadataToConsumptions do
  use Ecto.Migration

  def change do
    rename table(:transaction_request_consumption), to: table(:transaction_consumption)

    alter table(:transaction_consumption) do
      add :approved, :boolean, default: false
      add :finalized_at, :naive_datetime_usec
      add :expiration_date, :naive_datetime_usec
      add :expired_at, :naive_datetime_usec
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:transaction_consumption, [:metadata], using: "gin")
    create index(:transaction_consumption, [:encryption_version])
    create index(:transaction_consumption, [:expiration_date])
  end
end
