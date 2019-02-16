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

defmodule EWalletDB.Repo.Migrations.CreateTransactionRequestConsumption do
  use Ecto.Migration

  def change do
    create table(:transaction_request_consumption, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :amount, :decimal, precision: 81, scale: 0
      add :status, :string, default: "pending", null: false
      add :correlation_id, :string
      add :idempotency_token, :string, null: false
      add :user_id, references(:user, type: :uuid)
      add :transfer_id, references(:transfer, type: :uuid)
      add :transaction_request_id, references(:transaction_request, type: :uuid)
      add :minted_token_id, references(:minted_token, type: :uuid)
      add :balance_address, references(:balance, type: :string,  column: :address)

      timestamps()
    end

    create unique_index(:transaction_request_consumption, [:correlation_id])
    create unique_index(:transaction_request_consumption, [:idempotency_token])
  end
end
