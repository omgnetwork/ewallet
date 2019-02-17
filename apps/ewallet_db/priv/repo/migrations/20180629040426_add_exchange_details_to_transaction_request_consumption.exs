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

defmodule EWalletDB.Repo.Migrations.AddExchangeDetailsToTransactionRequestConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :exchange_account_uuid, references(:account, type: :uuid, column: :uuid)
      add :exchange_wallet_address, references(:wallet, type: :string, column: :address)
    end

    alter table(:transaction_consumption) do
      add :exchange_account_uuid, references(:wallet, type: :uuid, column: :uuid)
      add :exchange_wallet_address, references(:wallet, type: :string, column: :address)
    end
  end
end
