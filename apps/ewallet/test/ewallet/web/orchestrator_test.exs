defmodule EWallet.Web.OrchestratorTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.Orchestrator
  alias EWalletDB.{Account, Repo}

  defmodule MockOverlay do
    @behaviour EWallet.Web.V1.Overlay

    def preload_assocs, do: []
    def default_preload_assocs, do: []
    def sort_fields, do: []
    def search_fields, do: [:id]
    def self_filter_fields, do: []
    def filter_fields, do: []
  end

  describe "query/3" do
    test "orchestrates and paginates query" do
      _account1 = insert(:account)
      account2 = insert(:account)
      _account3 = insert(:account)

      # The 3rd param should match `MockAccountOverlay.search_fields/0`
      result = Orchestrator.query(Account, MockAccountOverlay, %{"search_term" => account2.id })

      assert %EWallet.Web.Paginator{} = result
      assert Enum.count(result.data) == 1
      assert List.first(result.data).id == account2.id
    end
  end

  describe "build_query/3" do
    test "processes the query with the overlay and attributes, but does not paginate" do
      _account1 = insert(:account)
      account2 = insert(:account)
      _account3 = insert(:account)

      # The 3rd param should match `MockAccountOverlay.search_fields/0`
      query = Orchestrator.build_query(Account, MockOverlay, %{"search_term" => account2.id})
      result = Repo.all(query)

      assert %Ecto.Query{} = query
      assert Enum.count(result) == 1
      assert List.first(result).id == account2.id
    end
  end

  describe "all/3" do

  end

  describe "one/3" do

  end

  describe "preload_to_query/3" do

  end
end
