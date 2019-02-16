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

defmodule EWallet.CSVExporterTest do
  use EWallet.DBCase
  import Ecto.Query
  import EWalletDB.Factory
  alias EWallet.CSVExporter
  alias EWallet.Web.V1.CSV.TransactionSerializer
  alias EWalletDB.{Export, Transaction}

  describe "start/4" do
    test "returns the pid and the export record" do
      # Insert transactions with a specific token to avoid side effects.
      token = insert(:token)
      transactions = insert_list(5, :transaction, to_token: token)

      user = insert(:user)

      {:ok, export} =
        Export.insert(%{
          schema: "some_schema",
          format: "csv",
          status: Export.new(),
          completion: 0,
          originator: user,
          params: %{},
          user_uuid: user.uuid
        })

      query = from(t in Transaction, where: t.to_token_uuid == ^token.uuid)

      {res, pid, export} = CSVExporter.start(export, export.schema, query, TransactionSerializer)

      assert res == :ok
      assert is_pid(pid)

      assert %Export{} = export
      assert export.estimated_size >= 0
      assert export.total_count == length(transactions)
    end
  end
end
