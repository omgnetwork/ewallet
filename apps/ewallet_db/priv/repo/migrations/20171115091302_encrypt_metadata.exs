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

defmodule EWalletDB.Repo.Migrations.EncryptMetadata do
  use Ecto.Migration

  def up do
    alter table(:balance) do
      remove :metadata
      add :metadata, :binary
      add :encryption_version, :binary
    end
    create index(:balance, [:encryption_version])

    alter table(:minted_token) do
      remove :metadata
      add :metadata, :binary
      add :encryption_version, :binary
    end
    create index(:minted_token, [:encryption_version])

    alter table(:user) do
      remove :metadata
      add :metadata, :binary
      add :encryption_version, :binary
    end
    create index(:user, [:encryption_version])
  end

  def down do
    alter table(:balance) do
      remove :metadata
      remove :encryption_version
      add :metadata, :map
    end

    alter table(:minted_token) do
      remove :metadata
      remove :encryption_version
      add :metadata, :map
    end

    alter table(:user) do
      remove :metadata
      remove :encryption_version
      add :metadata, :map
    end
  end
end
