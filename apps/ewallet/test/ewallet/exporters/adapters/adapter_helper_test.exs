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

defmodule EWallet.Exporters.AdapterHelperTest do
  use EWallet.DBCase
  import Ecto.Query
  alias EWallet.Exporters.AdapterHelper
  alias EWallet.Web.V1.CSV.TransactionSerializer
  alias EWalletDB.{Export, Transaction}

  setup do
    # Insert transactions with a newly inserted token to avoid side effects.
    token = insert(:token)
    user = insert(:user)
    transactions = insert_list(20, :transaction, to_token: token)
    serializer = TransactionSerializer

    # Suggest a number that will result in at least 3 chunks
    chunk_size =
      case Integer.floor_div(length(transactions), 3) do
        floor when floor >= 1 -> floor
        _ -> 1
      end

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

    {:ok, export} =
      Export.init(export, export.schema, length(transactions), 100, user)

    %{
      export: export,
      transactions: transactions,
      token: token,
      chunk_size: chunk_size,
      serializer: serializer
    }
  end

  describe "stream_to_file/5" do
    test "streams the data to the given file path", context do
      path = test_file_path("test-stream-to-file-#{:rand.uniform(999999)}.txt")

      refute File.exists?(path)

      query = from(t in Transaction, where: t.to_token_uuid == ^context.token.uuid)
      {res, result} = AdapterHelper.stream_to_file(path, context.export, query, context.serializer, context.chunk_size)

      assert res == :ok
      assert result == :ok
      assert File.exists?(path)

      # Clean up the created file after testing
      :ok = File.rm(path)
    end
  end

  describe "stream_to_chunk/4" do
    test "returns a stream", context do
      query = from(t in Transaction, where: t.to_token_uuid == ^context.token.uuid)
      stream = AdapterHelper.stream_to_chunk(context.export, query, context.serializer, context.chunk_size)

      assert %Stream{} = stream
    end
  end

  describe "setup_local_dir/0" do

  end

  describe "local_dir/0" do

  end

  describe "build_local_path/1" do

  end

  describe "update_export/3" do

  end

  describe "update_export/4" do

  end

  describe "store_error/2" do

  end
end
