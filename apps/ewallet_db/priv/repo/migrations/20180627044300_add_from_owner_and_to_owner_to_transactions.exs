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

defmodule EWalletDB.Repo.Migrations.AddFromOwnerAndToOwnerToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :from_account_uuid, references(:account, column: :uuid, type: :uuid)
      add :from_user_uuid, references(:user, column: :uuid, type: :uuid)
      add :to_account_uuid, references(:account, column: :uuid, type: :uuid)
      add :to_user_uuid, references(:user, column: :uuid, type: :uuid)
    end

    create index(:transaction, [:from_account_uuid, :to_account_uuid])
    create index(:transaction, [:to_account_uuid])
    create index(:transaction, [:from_user_uuid, :to_user_uuid])
    create index(:transaction, [:to_user_uuid])
  end
end
