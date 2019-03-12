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
    def default_preload_assocs, do: [:wallets]
    def sort_fields, do: [:id, :name]
    def search_fields, do: [:id, :name]
    def self_filter_fields, do: [:id, :name, :description, :inserted_at]
    def filter_fields, do: [:id, :name, :description, :inserted_at]
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

    test "returns records with the given `start_after`, `start_by` and `sort_by` is `desc`" do
      total = 10
      total_records = 5
      ensure_num_records(Account, total)

      records = from(a in Account, order_by: [desc: a.name])

      [record_1 | records] =
        records
        |> Repo.all()
        |> Enum.take(-total_records)

      attrs = %{
        "start_by" => "id",
        "start_after" => record_1.id,
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      # Is it not error when used with sort_by?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Is it name-descending sorted?
      name_desc_records =
        records
        |> Enum.map(fn record -> record.name end)
        |> Enum.sort()
        |> Enum.reverse()

      assert name_desc_records == Enum.map(data, fn record -> record.name end)
    end

    test "returns records with the given `start_after`, `start_by` and `sort_by` is `asc`" do
      total = 10
      total_records = 5
      ensure_num_records(Account, total)

      records = from(a in Account, order_by: a.id)

      [record_1 | records] =
        records
        |> Repo.all()
        |> Enum.take(-total_records)

      attrs = %{
        "start_by" => "id",
        "start_after" => record_1.id,
        "sort_by" => "id",
        "sort_dir" => "asc"
      }

      # Is it not error when used with sort_by?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Is it name-ascending sorted?
      name_desc_records =
        records
        |> Enum.map(fn record -> record.name end)

      assert name_desc_records == Enum.map(data, fn record -> record.name end)
    end

    test "returns records with the given `start_after`, `start_by` and `search_term` matched multiple records" do
      # Add search_term-unmatched records
      insert(:account, name: "account1")
      :timer.sleep(10)
      insert(:account, name: "account2")
      :timer.sleep(10)
      insert(:account, name: "account3")
      :timer.sleep(10)

      # Add search_term-matched records.
      my_account1 = insert(:account, name: "my_account1")
      :timer.sleep(10)
      my_account2 = insert(:account, name: "my_account2")

      attrs = %{
        "start_by" => "id",
        "start_after" => my_account1.id,
        "search_term" => "my_account"
      }

      # Is it not error when used with search_term?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Are the records correct?
      assert Enum.map(data, fn record -> record.id end) == [my_account2.id]
    end

    test "returns records with the given `start_after` nil, `start_by` and `search_term` matched 1 record" do
      insert(:account, name: "account1")
      account2 = insert(:account, name: "account2")
      insert(:account, name: "account3")

      attrs = %{
        "start_by" => "id",
        "start_after" => nil,
        "search_term" => account2.id
      }

      # Is it not error when used with sort_by?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Are the records correct?
      assert Enum.map(data, fn record -> record.id end) == [account2.id]
    end

    test "returns records with the given `start_after`, `start_by` and `match_any` matched multiple records" do
      account1 = insert(:account)
      :timer.sleep(10)
      account2 = insert(:account)
      :timer.sleep(10)
      account3 = insert(:account)

      attrs = %{
        "start_by" => "id",
        "start_after" => account2.id,
        "match_any" => [
          %{
            "field" => "id",
            "comparator" => "gt",
            "value" => account1.id
          }
        ]
      }

      # Is it not error when used with match_any?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Are the records correct?
      assert Enum.map(data, fn record -> record.id end) == [account3.id]
    end

    test "returns records with the given `start_after` nil, `start_by` and `match_any` matched 1 record" do
      account1 = insert(:account)
      insert(:account)
      insert(:account)

      attrs = %{
        "start_by" => "id",
        "start_after" => nil,
        "match_any" => [
          %{
            "field" => "name",
            "comparator" => "eq",
            "value" => account1.name
          }
        ]
      }

      # Is it not error when used with match_any?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Are the records correct?
      assert Enum.map(data, fn record -> record.id end) == [account1.id]
    end

    test "returns records with the given `start_after`, `start_by`, `match_any`, `sort_by` and `sort_dir`" do
      account1 = insert(:account)
      account2 = insert(:account)
      account3 = insert(:account)

      attrs = %{
        "start_by" => "id",
        "start_after" => account3.id,
        "match_any" => [
          %{
            "field" => "inserted_at",
            "comparator" => "gt",
            "value" => account1.inserted_at
          }
        ],
        "sort_by" => "created_at",
        "sort_dir" => "desc"
      }

      # Is it not error?
      assert %{data: data, pagination: _} = Orchestrator.query(Account, MockOverlay, attrs)

      # Are the accounts correct?
      assert Enum.map(data, fn record -> record.id end) == [account2.id]
    end

    test "returns error when `page` and `start_after` are used together" do
      attrs = %{
        "start_after" => "acc_1234",
        "page" => 1
      }

      assert {:error, :invalid_parameter, "`page` cannot be used with `start_after`"} =
               Orchestrator.query(Account, MockOverlay, attrs)
    end

    test "returns error when `page` and `start_by` are used together" do
      attrs = %{
        "start_by" => "id",
        "page" => 1
      }

      assert {:error, :invalid_parameter, "`page` cannot be used with `start_by`"} =
               Orchestrator.query(Account, MockOverlay, attrs)
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
               acc.wallets == [] || length(acc.wallets) > 0
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
      assert Enum.all?(result, fn acc -> acc.memberships.__struct__ == NotLoaded end)
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
               acc.wallets == [] || length(acc.wallets) > 0
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
      assert Enum.all?(result, fn acc -> acc.wallets.__struct__ == NotLoaded end)
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
      assert result.wallets == nil || length(result.wallets) > 0

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
      assert result.wallets.__struct__ == NotLoaded
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
               acc.wallets == [] || length(acc.wallets) > 0
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
      assert Enum.all?(result, fn acc -> acc.wallets.__struct__ == NotLoaded end)
    end
  end
end
