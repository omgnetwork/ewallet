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

defmodule EWallet.ExportGateTest do
  use EWallet.DBCase
  alias Ecto.Queryable
  alias EWallet.ExportGate
  alias EWallet.Web.V1.CSV.TransactionSerializer
  alias EWalletDB.Transaction

  describe "generate_url/1" do
    test "generates a url for AWS adapter" do
      attrs = %{adapter: "aws", filename: "some_file.csv"}

      {res, url} = ExportGate.generate_url(attrs)

      assert res == :ok
      assert String.valid?(url)
      assert String.starts_with?(url, "https://") || String.starts_with?(url, "http://")
    end

    test "generates a url for GCS adapter" do
      attrs = %{adapter: "gcs", filename: "some_file.csv"}

      {res, url} = ExportGate.generate_url(attrs)

      assert res == :ok
      assert String.valid?(url)
      assert String.starts_with?(url, "https://") || String.starts_with?(url, "http://")
    end

    test "returns nil for local adapter" do
      attrs = %{adapter: "local", filename: "some_file.csv"}

      {res, url} = ExportGate.generate_url(attrs)

      assert res == :ok
      assert url == nil
    end
  end

  describe "export/4" do
    test "creates an export on behalf of a user" do
      _ = insert_list(19, :transaction)

      query = Queryable.to_query(Transaction)
      attrs = %{originator: insert(:user)}

      {res, export} = ExportGate.export(query, "transaction", TransactionSerializer, attrs)

      assert res == :ok
      assert export.schema == "transaction"
      assert export.total_count == 19
      assert export.user_uuid == attrs.originator.uuid
    end

    test "creates an export on behalf of a key" do
      _ = insert_list(22, :transaction)

      query = Queryable.to_query(Transaction)
      attrs = %{originator: insert(:key)}

      {res, export} = ExportGate.export(query, "transaction", TransactionSerializer, attrs)

      assert res == :ok
      assert export.schema == "transaction"
      assert export.total_count == 22
      assert export.key_uuid == attrs.originator.uuid
    end
  end
end
