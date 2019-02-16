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

defmodule EWalletDB.Repo.Migrations.RenameUnicityConstraintForConsumptionCorrelationID do
  use Ecto.Migration

  def change do
    drop index(:transaction_consumption, [:correlation_id],
               name: :transaction_request_consumption_correlation_id_index)
    create unique_index(:transaction_consumption, [:correlation_id])
  end
end
