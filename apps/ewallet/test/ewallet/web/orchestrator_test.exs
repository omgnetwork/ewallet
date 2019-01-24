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

defmodule EWallet.Web.OrchestratorTest do
  use EWallet.DBCase, async: true
  import Ecto.Query
  import EWalletDB.Factory
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Orchestrator
  alias EWalletDB.{Account, Repo}

  defmodule MockOverlay do
    @behaviour EWallet.Web.V1.Overlay

    def pagination_fields, do: [:id]
    def preload_assocs, do: [:categories]
    def default_preload_assocs, do: [:parent]
    def sort_fields, do: [:id, :name]
    def search_fields, do: [:id]
    def self_filter_fields, do: [:id, :name, :description]
    def filter_fields, do: [:id, :name, :description]
  end

  describe "query/3" do
    test "returns an `EWallet.Web.Paginator`" do
      assert %EWallet.Web.Paginator{} = Orchestrator.query(Account, MockOverlay)
    end

    test "performs search with the given overlay and attributes" do
      _account1 = insert(:account)
      account2 = insert(:account)
      _account3 = insert(:account)

      # The 3rd param should match `MockOverlay.search_fields/0`
      result = Orchestrator.query(Account, MockOverlay, %{"search_term" => account2.id})

      assert %EWallet.Web.Paginator{} = result
      assert Enum.count(result.data) == 1
      assert List.first(result.data).id == account2.id
    end

    test "returns :query_field_not_allowed error if the field is not in the allowed list" do
      attrs = %{
        "match_all" => [
          %{
            "field" => "status",
            "comparator" => "eq",
            "value" => "pending"
          }
        ]
      }

      {res, error, params} = Orchestrator.query(Account, MockOverlay, attrs)

      assert res == :error
      assert error == :query_field_not_allowed
      assert params == [field_name: "status"]
    end

    test "returns records when `sort_by` and `start_by` are presented" do
      total = 10
      total_records = 5
      ensure_num_records(Account, total)

      records = from(a in Account, order_by: a.id)

      records =
        records
        |> Repo.all()
        # Take last `total_records` elements
        |> Enum.take(-total_records)

      first_record_id =
        records
        |> Enum.map(fn record -> record.id end)
        |> Enum.at(0)

      attrs = %{
        "start_by" => "id",
        "start_from" => first_record_id,
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      # Is it not error when used with sort_by?
      assert %{data: data, pagination: pagination} =
               Orchestrator.query(Account, MockOverlay, attrs)

      # Is it name-descending sorted?
      name_desc_records =
        records
        |> Enum.map(fn record -> record.name end)
        |> Enum.sort()
        |> Enum.reverse()

      assert name_desc_records == Enum.map(data, fn elem -> elem.name end)

      # Is it all has an id >= `first_record_id`?
      assert Enum.all?(data, fn elem -> elem.id >= first_record_id end)
    end
  end

  describe "build_query/3" do
    test "returns an `Ecto.Query`" do
      assert %Ecto.Query{} = Orchestrator.build_query(Account, MockOverlay)
    end

    test "preloads with the overlay's default preloads when 'preload' attribute is not given" do
      _account = insert(:account)

      result =
        Account
        |> Orchestrator.build_query(MockOverlay)
        |> Repo.all()

      # Preloaded fields must no longer be `%NotLoaded{}`
      assert Enum.all?(result, fn acc ->
               acc.parent == nil || acc.parent.__struct__ != NotLoaded
             end)

      # `categories` fields are not preloaded and so they should be `%NotLoaded{}`
      assert Enum.all?(result, fn acc -> acc.categories.__struct__ == NotLoaded end)
    end

    test "preloads with the given 'preload' attribute when given" do
      _account = insert(:account)

      result =
        Account
        |> Orchestrator.build_query(MockOverlay, %{"preload" => [:categories]})
        |> Repo.all()

      # Preloaded categories must be a list
      assert Enum.all?(result, fn acc -> is_list(acc.categories) end)

      # `parent` is no longer preloaded because the "preload" attribute is specified
      assert Enum.all?(result, fn acc -> acc.parent.__struct__ == NotLoaded end)
    end

    test "performs match_all with the given overlay and attributes" do
      account1 = insert(:account, name: "Name Matched 1", description: "Description 1")
      account2 = insert(:account, name: "Name Unmatched 2", description: "Description 2")
      account3 = insert(:account, name: "Name Matched 3", description: "Description 3")

      attrs = %{
        "match_all" => [
          %{
            "field" => "name",
            "comparator" => "contains",
            "value" => "Name Matched"
          },
          %{
            "field" => "description",
            "comparator" => "neq",
            "value" => "Description 1"
          }
        ]
      }

      result =
        Account
        |> Orchestrator.build_query(MockOverlay, attrs)
        |> Repo.all()

      refute Enum.any?(result, fn account -> account.id == account1.id end)
      refute Enum.any?(result, fn account -> account.id == account2.id end)
      assert Enum.any?(result, fn account -> account.id == account3.id end)
    end

    test "perform match_any filter with the given overlay and attributes" do
      account1 = insert(:account, name: "Name Matched 1", description: "Description 1")
      account2 = insert(:account, name: "Name Unmatched 2", description: "Description 2")
      account3 = insert(:account, name: "Name Matched 3", description: "Description 3")

      attrs = %{
        "match_any" => [
          %{
            "field" => "name",
            "comparator" => "contains",
            "value" => "Matched 2"
          },
          %{
            "field" => "description",
            "comparator" => "contains",
            "value" => "Description 3"
          }
        ]
      }

      result =
        Account
        |> Orchestrator.build_query(MockOverlay, attrs)
        |> Repo.all()

      refute Enum.any?(result, fn account -> account.id == account1.id end)
      assert Enum.any?(result, fn account -> account.id == account2.id end)
      assert Enum.any?(result, fn account -> account.id == account3.id end)
    end

    test "handles :not_allowed error mid-way" do
      # This assumes that the order of `Orchestrator.build_query/3`
      # calls `MatchAnyParser.to_query/3` mid way.
      attrs = %{
        "match_any" => [
          %{
            "field" => "unallowed_field",
            "comparator" => "eq",
            "value" => "pending"
          }
        ]
      }

      {res, error, params} = Orchestrator.build_query(Account, MockOverlay, attrs)

      assert res == :error
      assert error == :not_allowed
      assert params == "unallowed_field"
    end
  end

  describe "all/3" do
    test "preloads with the overlay's default preloads when 'preload' attribute is not given" do
      _account = insert(:account)

      {:ok, result} =
        Account
        |> Repo.all()
        |> Orchestrator.all(MockOverlay)

      # Preloaded fields must no longer be `%NotLoaded{}`
      assert Enum.all?(result, fn acc ->
               acc.parent == nil || acc.parent.__struct__ != NotLoaded
             end)

      # `categories` fields are not preloaded and so they should be `%NotLoaded{}`
      assert Enum.all?(result, fn acc -> acc.categories.__struct__ == NotLoaded end)
    end

    test "preloads with the given 'preload' attribute when given" do
      _account = insert(:account)

      {:ok, result} =
        Account
        |> Repo.all()
        |> Orchestrator.all(MockOverlay, %{"preload" => [:categories]})

      # Preloaded categories must be a list
      assert Enum.all?(result, fn acc -> is_list(acc.categories) end)

      # `parent` is no longer preloaded because the "preload" attribute is specified
      assert Enum.all?(result, fn acc -> acc.parent.__struct__ == NotLoaded end)
    end
  end

  describe "one/3" do
    test "preloads with the overlay's default preloads when 'preload' attribute is not given" do
      _account = insert(:account)

      {:ok, result} =
        Account
        |> Repo.all()
        |> List.first()
        |> Orchestrator.one(MockOverlay)

      # Preloaded fields must no longer be `%NotLoaded{}`
      assert result.parent == nil || result.parent.__struct__ != NotLoaded

      # `categories` fields are not preloaded and so they should be `%NotLoaded{}`
      assert result.categories.__struct__ == NotLoaded
    end

    test "preloads with the given 'preload' attribute when given" do
      _account = insert(:account)

      {:ok, result} =
        Account
        |> Repo.all()
        |> List.first()
        |> Orchestrator.one(MockOverlay, %{"preload" => [:categories]})

      # Preloaded categories must be a list
      assert is_list(result.categories)

      # `parent` is no longer preloaded because the "preload" attribute is specified
      assert result.parent.__struct__ == NotLoaded
    end
  end

  describe "preload_to_query/3" do
    test "preloads with the overlay's default preloads when 'preload' attribute is not given" do
      _account = insert(:account)

      result =
        Account
        |> Orchestrator.preload_to_query(MockOverlay)
        |> Repo.all()

      # Preloaded fields must no longer be `%NotLoaded{}`
      assert Enum.all?(result, fn acc ->
               acc.parent == nil || acc.parent.__struct__ != NotLoaded
             end)

      # `categories` fields are not preloaded and so they should be `%NotLoaded{}`
      assert Enum.all?(result, fn acc -> acc.categories.__struct__ == NotLoaded end)
    end

    test "preloads with the given 'preload' attribute when given" do
      _account = insert(:account)

      result =
        Account
        |> Orchestrator.preload_to_query(MockOverlay, %{"preload" => [:categories]})
        |> Repo.all()

      # Preloaded categories must be a list
      assert Enum.all?(result, fn acc -> is_list(acc.categories) end)

      # `parent` is no longer preloaded because the "preload" attribute is specified
      assert Enum.all?(result, fn acc -> acc.parent.__struct__ == NotLoaded end)
    end
  end
end
