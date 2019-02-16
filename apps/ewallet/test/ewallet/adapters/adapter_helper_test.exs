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

defmodule EWallet.AdapterHelperTest do
  use EWallet.DBCase
  import Ecto.Query
  import EWalletDB.Factory
  alias EWallet.AdapterHelper
  alias EWallet.Web.V1.CSV.TransactionSerializer
  alias EWalletDB.{Export, Transaction}
  alias Ecto.UUID
  alias Utils.Helper.PidHelper
  alias Utils.Helpers.PathResolver

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

    {:ok, export} = Export.init(export, export.schema, length(transactions), 100, user)

    query = from(t in Transaction, where: t.to_token_uuid == ^token.uuid)

    # File things
    root = PathResolver.static_dir(:url_dispatcher)
    uuid = UUID.generate()
    path = Path.join(["private", uuid])
    path_abs = Path.join([root, path])

    :ok = File.mkdir_p!(path_abs)

    on_exit(fn ->
      _ = File.rm_rf!(path_abs)
    end)

    %{
      export: export,
      query: query,
      preloads: [],
      serializer: serializer,
      transactions: transactions,
      chunk_size: chunk_size,
      root: root,
      uuid: uuid,
      path: path,
      path_abs: path_abs
    }
  end

  describe "stream_to_file/5" do
    test "streams the data to the given file path", context do
      path = Path.join(context.path_abs, "test-stream-to-file-#{:rand.uniform(999_999)}.txt")

      refute File.exists?(path)

      {res, result} =
        AdapterHelper.stream_to_file(
          path,
          context.export,
          context.query,
          context.preloads,
          context.serializer,
          context.chunk_size
        )

      assert res == :ok
      assert result == :ok
      assert File.exists?(path)
    end
  end

  describe "stream_to_chunk/4" do
    test "returns a stream", context do
      stream =
        AdapterHelper.stream_to_chunk(
          context.export,
          context.query,
          context.preloads,
          context.serializer,
          context.chunk_size
        )

      assert %Stream{} = stream
    end
  end

  describe "setup_local_dir/0" do
    test "returns :ok" do
      res = AdapterHelper.setup_local_dir()
      assert res == :ok
    end
  end

  describe "local_dir/0" do
    test "returns a string containing url_dispatcher path" do
      path = AdapterHelper.local_dir()
      assert String.match?(path, ~r/^.+\/url_dispatcher\/priv\/static\//)
    end
  end

  describe "build_local_path/1" do
    test "returns a string starting with the root dir and ends with the given file name" do
      path = AdapterHelper.build_local_path("local_file_name.txt")
      assert String.match?(path, ~r/^.+\/url_dispatcher\/priv\/static\/.*\/local_file_name\.txt$/)
    end
  end

  describe "update_export/3" do
    test "returns an export with the updated status and completion", context do
      refute context.export.status == Export.completed()
      refute context.export.completion == 100

      {res, export} = AdapterHelper.update_export(context.export, Export.completed(), 100)

      assert res == :ok
      assert export.status == Export.completed()
      assert export.completion == 100
    end
  end

  describe "update_export/4" do
    test "returns an export with the updated status, completion and pid", context do
      refute context.export.status == Export.completed()
      refute context.export.completion == 100
      refute context.export.pid

      pid = PidHelper.pid_to_binary(self())

      {res, export} = AdapterHelper.update_export(context.export, Export.completed(), 100, pid)

      assert res == :ok
      assert export.status == Export.completed()
      assert export.completion == 100
      assert export.pid == pid
    end
  end

  describe "store_error/2" do
    test "returns an export with the given error", context do
      refute context.export.status == Export.failed()
      assert context.export.failure_reason == nil

      {res, export} = AdapterHelper.store_error(context.export, "some_error")

      assert res == :ok
      assert export.status == Export.failed()
      assert export.failure_reason == "some_error"
    end
  end
end
