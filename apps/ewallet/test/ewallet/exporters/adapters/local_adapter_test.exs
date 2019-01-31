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

defmodule EWallet.Exporters.LocalAdapterTest do
  use EWallet.DBCase
  import Ecto.Query
  import EWalletDB.Factory
  alias EWallet.Exporters.LocalAdapter
  alias EWallet.Web.V1.CSV.TransactionSerializer
  alias EWalletDB.{Export, Transaction}

  setup do
    # Insert transactions with a newly inserted token to avoid side effects.
    token = insert(:token)
    user = insert(:user)
    transactions = insert_list(20, :transaction, to_token: token)
    serializer = TransactionSerializer

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

    {:ok, export} = Export.init(export, export.schema, length(transactions), 1024, user)

    query = from(t in Transaction, where: t.to_token_uuid == ^token.uuid)

    %{
      export: export,
      query: query,
      preloads: [],
      serializer: serializer
    }
  end

  describe "generate_signed_url/1" do
    test "returns nil", context do
      assert LocalAdapter.generate_signed_url(context.export) === {:ok, nil}
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

      {res, export} = LocalAdapter.upload(args)

      assert res == :ok
      assert export.status == Export.completed()
    end
  end
end
