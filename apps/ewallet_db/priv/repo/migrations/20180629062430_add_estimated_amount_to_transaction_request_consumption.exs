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

defmodule EWalletDB.Repo.Migrations.AddEstimatedAmountToTransactionRequestConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_consumption) do
      add :exchange_pair_uuid, references(:exchange_pair, type: :uuid, column: :uuid)
      add :estimated_at, :naive_datetime_usec
      add :estimated_rate, :float
      add :estimated_request_amount, :decimal, precision: 81, scale: 0
      add :estimated_consumption_amount, :decimal, precision: 81, scale: 0
    end
  end
end
