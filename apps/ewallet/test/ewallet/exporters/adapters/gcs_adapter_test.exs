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

defmodule EWallet.Exporters.GCSAdapterTest do
  use EWallet.DBCase
  import Ecto.Query
  import EWalletDB.Factory
  alias EWallet.Exporters.GCSAdapter
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

    {:ok, export} = Export.init(export, export.schema, length(transactions), 100, user)

    query = from(t in Transaction, where: t.to_token_uuid == ^token.uuid)

    %{
      export: export,
      query: query,
      preloads: [],
      serializer: serializer,
      transactions: transactions,
      chunk_size: chunk_size
    }
  end

  describe "generate_signed_url/1" do
    test "returns a url", context do
      {res, url} = GCSAdapter.generate_signed_url(context.export)

      assert res == :ok
      assert is_url?(url)
    end
  end

  describe "upload/1" do
    test "returns a successful export", context do
      args = %{
        export: context.export,
        query: context.query,
        preloads: context.preloads,
        serializer: context.serializer
      }

      {res, export} = GCSAdapter.upload(args)

      assert res == :ok
      assert export.status == Export.completed()
    end
  end
end
