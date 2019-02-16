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

defmodule EWalletDB.Repo.Migrations.MoveLedgerResponseIntoSpecificFields do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletConfig.Encrypted
  alias EWalletDB.Repo

  def up do
    alter table(:transfer) do
      add :entry_uuid, :string
      add :error_code, :string
      add :error_description, :string
      add :error_data, :map
    end

    flush()

    query = from(t in "transfer",
                 select: [t.uuid, t.ledger_response],
                 lock: "FOR UPDATE")

    for [uuid, ledger_response] <- Repo.all(query) do
      if ledger_response != nil do
        {:ok, ledger_response} = Encrypted.Map.load(ledger_response)
        description = get_data_or_description(ledger_response["description"], :description)
        data = get_data_or_description(ledger_response["description"], :data)

        query = from(t in "transfer",
                     where: t.uuid == ^uuid,
                     update: [set: [entry_uuid: ^ledger_response["entry_uuid"],
                                    error_code: ^ledger_response["code"],
                                    error_description: ^description,
                                    error_data: ^data
                                    ]])

        Repo.update_all(query, [])
      end
    end

    flush()

    alter table(:transfer) do
      remove :ledger_response
    end
  end

  def down do
    alter table(:transfer) do
      add :ledger_response, :map
    end

    flush()

    query = from(t in "transfer",
                 select: [t.uuid, t.entry_uuid, t.error_code, t.error_description, t.error_data],
                 lock: "FOR UPDATE")

    for [uuid, entry_uuid, error_code, error_description, error_data] <- Repo.all(query) do
      {:ok, ledger_response} = EncryptedMapField.cast(%{
        entry_uuid: entry_uuid,
        error_code: error_code,
        error_description: error_description || error_data
      })

      query = from(t in "transfer",
                   where: t.uuid == ^uuid,
                   update: [set: [ledger_response: ^ledger_response]])

      Repo.update_all(query, [])
    end

    alter table(:transfer) do
      remove :entry_uuid
      remove :error_code
      remove :error_description
      remove :error_data
    end
  end

  defp get_data_or_description(nil, _) do
    nil
  end

  defp get_data_or_description(desc, :description) when is_map(desc) do
    nil
  end

  defp get_data_or_description(desc, :description) when is_binary(desc) do
    desc
  end

  defp get_data_or_description(desc, :data) when is_map(desc) do
    desc
  end

  defp get_data_or_description(desc, :data) when is_binary(desc) do
    nil
  end
end
