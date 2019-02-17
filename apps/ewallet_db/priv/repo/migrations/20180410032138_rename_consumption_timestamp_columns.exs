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

defmodule EWalletDB.Repo.Migrations.RenameConsumptionTimestampColumns do
  use Ecto.Migration

  def up do
    rename table(:transaction_consumption), :finalized_at, to: :approved_at

    alter table(:transaction_consumption) do
      add :confirmed_at, :naive_datetime_usec
      add :rejected_at, :naive_datetime_usec
      add :failed_at, :naive_datetime_usec
      remove :approved
    end
  end

  def down do
    rename table(:transaction_consumption), :approved_at, to: :finalized_at

    alter table(:transaction_consumption) do
      remove :confirmed_at
      remove :rejected_at
      remove :failed_at
      add :approved, :boolean
    end
  end
end
