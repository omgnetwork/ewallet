defmodule EWallet.Web.OrchestratorTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Orchestrator
  alias EWalletDB.{Account, Repo}

  defmodule MockOverlay do
    @behaviour EWallet.Web.V1.Overlay

    def preload_assocs, do: [:categories]
    def default_preload_assocs, do: [:parent]
    def sort_fields, do: [:id]
    def search_fields, do: [:id]
    def self_filter_fields, do: []
    def filter_fields, do: [:id, :name, :description]
  end

  describe "query/3" do
    test "returns an `EWallet.Web.Paginator`" do
      assert %EWallet.Web.Paginator{} = Orchestrator.query(Account, MockOverlay)
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

      attrs =
        %{
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

      attrs =
        %{
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

    test "performs search with the given overlay and attributes" do
      _account1 = insert(:account)
      account2 = insert(:account)
      _account3 = insert(:account)

      # The 3rd param should match `MockOverlay.search_fields/0`
      result = Orchestrator.query(Account, MockOverlay, %{"search_term" => account2.id })

      assert %EWallet.Web.Paginator{} = result
      assert Enum.count(result.data) == 1
      assert List.first(result.data).id == account2.id
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
