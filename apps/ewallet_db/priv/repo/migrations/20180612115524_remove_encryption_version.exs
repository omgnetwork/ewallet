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

defmodule EWalletDB.Repo.Migrations.RemoveEncryptionVersion do
  use Ecto.Migration

  def up do
    remove_encryption_version(:account)
    remove_encryption_version(:token)
    remove_encryption_version(:transaction_consumption)
    remove_encryption_version(:transaction_request)
    remove_encryption_version(:transfer)
    remove_encryption_version(:user)
    remove_encryption_version(:wallet)
  end

  def down do
    add_encryption_version(:account)
    add_encryption_version(:token)
    add_encryption_version(:transaction_consumption)
    add_encryption_version(:transaction_request)
    add_encryption_version(:transfer)
    add_encryption_version(:user)
    add_encryption_version(:wallet)
  end

  # priv

  defp remove_encryption_version(table_name) do
    alter table(table_name) do
      remove :encryption_version
    end
  end

  defp add_encryption_version(table_name) do
    alter table(table_name) do
      add :encryption_version, :binary
    end

    create index(table_name, [:encryption_version])
  end
end
