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

defmodule EWalletDB.Repo.Migrations.RenameTransferToTransaction do
  use Ecto.Migration

  def up do
    # Rename table
    rename table(:transfer), to: table(:transaction)

    # Add new indices
    create index(:transaction, [:id])
    create index(:transaction, [:metadata], using: "gin")
    create unique_index(:transaction, [:idempotency_token])

    # Remove old indices after the new ones are added
    drop index(:transaction, [:metadata], name: :transfer_metadata_index)
    drop index(:transaction, [:id], name: :transfer_id_index)
    drop index(:transaction, [:idempotency_token], name: :transfer_idempotency_token_index)

    # Add new constraints
    alter table(:transaction) do
      modify :from, references(:wallet, type: :string, column: :address), null: false
      modify :from_token_uuid, references(:token, type: :uuid, column: :uuid), null: false
      modify :to, references(:wallet, type: :string, column: :address), null: false
      modify :to_token_uuid, references(:token, type: :uuid, column: :uuid), null: false
    end

    # Remove old constraints after the new ones are added
    drop constraint(:transaction, "transfer_from_fkey")
    drop constraint(:transaction, "transfer_from_token_uuid_fkey")
    drop constraint(:transaction, "transfer_to_fkey")
    drop constraint(:transaction, "transfer_to_token_uuid_fkey")
  end

  def down do
    rename table(:transaction), to: table(:transfer)

    # Add new indices
    create index(:transfer, [:id])
    create index(:transfer, [:metadata], using: "gin")
    create unique_index(:transfer, [:idempotency_token])

    # Remove old indices after the new ones are added
    drop index(:transfer, [:metadata], name: :transaction_metadata_index)
    drop index(:transfer, [:id], name: :transaction_id_index)
    drop index(:transfer, [:idempotency_token], name: :transaction_idempotency_token_index)

    # Add new constraints
    alter table(:transfer) do
      modify :from, references(:wallet, type: :string, column: :address), null: false
      modify :from_token_uuid, references(:token, type: :uuid, column: :uuid), null: false
      modify :to, references(:wallet, type: :string, column: :address), null: false
      modify :to_token_uuid, references(:token, type: :uuid, column: :uuid), null: false
    end

    # Remove old constraints after the new ones are added
    drop constraint(:transfer, "transaction_from_fkey")
    drop constraint(:transfer, "transaction_from_token_uuid_fkey")
    drop constraint(:transfer, "transaction_to_fkey")
    drop constraint(:transfer, "transaction_to_token_uuid_fkey")
  end
end
