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

defmodule EWalletDB.Repo.Migrations.RenameIdToUuid do
  use Ecto.Migration

  @tables [
    :account,
    :api_key,
    :auth_token,
    :balance,
    :forget_password_request,
    :invite,
    :key,
    :membership,
    :mint,
    :minted_token,
    :role,
    :transaction_consumption,
    :transaction_request,
    :transfer,
    :user
  ]

  def up do
    Enum.each(@tables, fn(table) ->
      rename table(table), :id, to: :uuid
    end)
  end

  def down do
    Enum.each(@tables, fn(table) ->
      rename table(table), :uuid, to: :id
    end)
  end
end
