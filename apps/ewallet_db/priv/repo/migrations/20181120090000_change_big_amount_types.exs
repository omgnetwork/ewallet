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

defmodule EWalletDB.Repo.Migrations.ChangeBigAmountTypes do
  use Ecto.Migration

  def up do
    alter table(:token) do
      modify :subunit_to_unit, :decimal, precision: 36, scale: 0, null: false
    end

    alter table(:mint) do
      modify :amount, :decimal, precision: 36, scale: 0, null: false
    end

    alter table(:transaction) do
      modify :from_amount, :decimal, precision: 36, scale: 0, null: false
      modify :to_amount, :decimal, precision: 36, scale: 0, null: false
    end

    alter table(:transaction_request) do
      modify :amount, :decimal, precision: 36, scale: 0
    end

    alter table(:transaction_consumption) do
      modify :amount, :decimal, precision: 36, scale: 0
      modify :estimated_request_amount, :decimal, precision: 36, scale: 0
      modify :estimated_consumption_amount, :decimal, precision: 36, scale: 0
    end
  end

  def down do
    alter table(:token) do
      modify :subunit_to_unit, :decimal, precision: 81, scale: 0, null: false
    end

    alter table(:mint) do
      modify :amount, :decimal, precision: 81, scale: 0, null: false
    end

    alter table(:transaction) do
      modify :from_amount, :decimal, precision: 81, scale: 0, null: false
      modify :to_amount, :decimal, precision: 81, scale: 0, null: false
    end

    alter table(:transaction_request) do
      modify :amount, :decimal, precision: 81, scale: 0
    end

    alter table(:transaction_consumption) do
      modify :amount, :decimal, precision: 81, scale: 0
      modify :estimated_request_amount, :decimal, precision: 81, scale: 0
      modify :estimated_consumption_amount, :decimal, precision: 81, scale: 0
    end
  end
end
