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

defmodule EWalletDB.Repo.Migrations.UpdateTransactionsOwners do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    query = from(t in "transaction",
                 select: [t.uuid,
                          t.from,
                          t.to],
                 where: (is_nil(t.from_account_uuid) and is_nil(t.from_user_uuid)) or
                        (is_nil(t.to_account_uuid) and is_nil(t.to_user_uuid)),
                 lock: "FOR UPDATE")

    for [uuid, from, to] <- Repo.all(query) do
      [from_account_uuid, from_user_uuid] = Repo.one(from(t in "wallet",
                               select: [t.account_uuid,
                                        t.user_uuid],
                               where: t.address == ^from))
      [to_account_uuid, to_user_uuid] = Repo.one(from(t in "wallet",
                               select: [t.account_uuid,
                                        t.user_uuid],
                               where: t.address == ^to))

      query = from(t in "transaction",
                   where: t.uuid == ^uuid,
                   update: [set: [
                     from_account_uuid: ^from_account_uuid,
                     from_user_uuid: ^from_user_uuid,
                     to_account_uuid: ^to_account_uuid,
                     to_user_uuid: ^to_user_uuid
                   ]])

      Repo.update_all(query, [])
    end
  end

  def down do
    # do nothing
  end
end
