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

defmodule EWalletDB.SoftDeleteTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.{Factory, SoftDelete}
  alias EWalletDB.{Key, Repo}
  alias ActivityLogger.System

  describe "exclude_deleted/1" do
    test "returns records that are not soft-deleted" do
      key = insert(:key)
      {:ok, deleted} = :key |> insert() |> Key.delete(%System{})

      result =
        Key
        |> exclude_deleted()
        |> Repo.all()

      refute Enum.any?(result, fn k -> k.id == deleted.id end)
      assert Enum.any?(result, fn k -> k.id == key.id end)
    end
  end

  describe "deleted?/1" do
    test "returns true if record is soft-deleted" do
      {:ok, key} = :key |> insert() |> Key.delete(%System{})
      assert Key.deleted?(key)
    end

    test "returns true if record is not soft-deleted" do
      key = insert(:key)
      refute Key.deleted?(key)
    end
  end

  describe "delete/2" do
    test "returns an :ok with the soft-deleted record" do
      {res, key} = :key |> insert() |> Key.delete(%System{})

      assert res == :ok
      assert Key.deleted?(key)
    end

    test "populates :deleted_at field" do
      {:ok, key} = :key |> insert() |> Key.delete(%System{})
      assert key.deleted_at != nil
    end
  end

  describe "restore/2" do
    test "returns an :ok with the record not soft-deleted" do
      {res, key} = :key |> insert() |> Key.restore(%System{})

      assert res == :ok
      refute Key.deleted?(key)
    end

    test "set :deleted_at field to nil" do
      {:ok, key} = :key |> insert() |> Key.restore(%System{})
      assert key.deleted_at == nil
    end
  end
end
