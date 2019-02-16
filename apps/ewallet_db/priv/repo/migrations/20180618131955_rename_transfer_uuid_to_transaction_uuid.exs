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

defmodule EWalletDB.Repo.Migrations.RenameTransferUuidToTransactionUuid do
  use Ecto.Migration

  def up do
    to_transaction_uuid(:mint, "mint_transfer_id_fkey")
    to_transaction_uuid(:transaction_consumption, "transaction_request_consumption_transfer_id_fkey")
  end

  def down do
    to_transfer_uuid(:mint, "mint_transfer_id_fkey")
    to_transfer_uuid(:transaction_consumption, "transaction_request_consumption_transfer_id_fkey")
  end

  defp to_transaction_uuid(table, drop_constraint) do
    # Rename the field
    rename table(table), :transfer_uuid, to: :transaction_uuid

    # Add the new constraint
    alter table(table) do
      modify :transaction_uuid, references(:transaction, type: :uuid,
                                                         column: :uuid)
    end

    # Remove the old one
    drop constraint(table, drop_constraint)
  end

  defp to_transfer_uuid(table, constraint_name) do
    # Rename the field
    rename table(table), :transaction_uuid, to: :transfer_uuid

    # Add the new constraint
    alter table(table) do
      modify :transfer_uuid, references(:transaction, type: :uuid,
                                                      column: :uuid,
                                                      name: constraint_name)
    end

    # Remove the old one
    drop constraint(table, "#{table}_transaction_uuid_fkey")
  end
end
