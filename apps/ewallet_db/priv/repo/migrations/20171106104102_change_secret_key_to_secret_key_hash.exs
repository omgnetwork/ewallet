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

defmodule EWalletDB.Repo.Migrations.ChangeSecretKeyToSecretKeyHash do
  use Ecto.Migration
  import Ecto.Query
  alias Utils.Helpers.Crypto
  alias EWalletDB.Repo

  def up do
    alter table(:key) do
      add :secret_key_hash, :string
    end

    create unique_index(:key, [:secret_key_hash])
    create unique_index(:key, [:access_key])

    flush()

    query =
      from(k in "key",
        select: [k.id, k.secret_key],
        where: k.secret_key != "" and is_nil(k.secret_key_hash),
        lock: "FOR UPDATE")

    query
    |> Repo.all()
    |> migrate_secret_keys()

    drop unique_index(:key, [:access_key, :secret_key])

    alter table(:key) do
      remove :secret_key
      modify :secret_key_hash, :string, null: false
    end
  end

  defp migrate_secret_keys(keys) do
    for [id, secret_key] <- keys do
      secret_key_hash = Crypto.hash_password(secret_key)
      query =
        from(k in "key",
          where: k.id == ^id,
          update: [set: [secret_key_hash: ^secret_key_hash]])

      Repo.update_all(query, [])
    end
  end
end
