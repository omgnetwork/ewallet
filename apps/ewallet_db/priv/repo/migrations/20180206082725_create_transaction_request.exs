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

defmodule EWalletDB.Repo.Migrations.CreateTransactionRequest do
  use Ecto.Migration

  def change do
    create table(:transaction_request, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false
      add :amount, :decimal, precision: 81, scale: 0
      add :status, :string, default: "pending", null: false
      add :correlation_id, :string
      add :user_id, references(:user, type: :uuid)
      add :minted_token_id, references(:minted_token, type: :uuid)
      add :balance_address, references(:balance, type: :string,  column: :address)

      timestamps()
    end

    create unique_index(:transaction_request, [:correlation_id])
  end
end
