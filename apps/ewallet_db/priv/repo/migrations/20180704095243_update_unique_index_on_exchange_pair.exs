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

defmodule EWalletDB.Repo.Migrations.UpdateUniqueIndexOnExchangePair do
  use Ecto.Migration

  def up do
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid], where: "deleted_at IS NULL")
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
  end

  def down do
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid], where: "deleted_at IS NULL")
  end
end
