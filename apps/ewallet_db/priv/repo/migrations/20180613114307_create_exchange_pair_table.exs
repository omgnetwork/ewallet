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

defmodule EWalletDB.Repo.Migrations.CreateExchangePairTable do
  use Ecto.Migration

  def change do
    create table(:exchange_pair, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false
      add :name, :string, null: false
      add :from_token_uuid, references(:token, column: :uuid, type: :uuid)
      add :to_token_uuid, references(:token, column: :uuid, type: :uuid)
      add :rate, :float, null: false

      timestamps()
      add :deleted_at, :naive_datetime_usec
    end

    create unique_index(:exchange_pair, [:id])

    # This allows for only one pair `from_token`, `to_token` and `deleted_at: null`,
    # and still allows for multiple deleted pairs.
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
  end
end
