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

defmodule EWalletDB.Repo.Migrations.CreateTransfers do
  use Ecto.Migration

  def change do
    create table(:transfer, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :idempotency_token, :string, null: false
      add :status, :string, default: "pending", null: false
      add :type, :string, default: "internal", null: false
      add :payload, :binary, null: false
      add :ledger_response, :binary
      add :metadata, :binary
      add :encryption_version, :binary
      timestamps()
    end

    create unique_index(:transfer, [:idempotency_token])
  end
end
