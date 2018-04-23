defmodule EWallet.Web.PaginatorTest do
  use EWallet.DBCase
  import Ecto.Query
  alias EWallet.Web.Paginator
  alias EWalletDB.{Repo, Account}

  describe "EWallet.Web.Paginator.paginate_attrs/2" do
    test "paginates with default values if attrs not given" do
      ensure_num_records(Account, 10)

      paginator = Paginator.paginate_attrs(Account, %{})
      assert Enum.count(paginator.data) == 10
      assert paginator.pagination.per_page == 10
    end

    test "returns a paginator with the given page and per_page" do
      ensure_num_records(Account, 10)

      paginator = Paginator.paginate_attrs(Account, %{"page" => 2, "per_page" => 3})
      assert paginator.pagination.current_page == 2
      assert paginator.pagination.per_page == 3

      # Try with different values to make sure the attributes are respected
      paginator = Paginator.paginate_attrs(Account, %{"page" => 3, "per_page" => 4})
      assert paginator.pagination.current_page == 3
      assert paginator.pagination.per_page == 4
    end

    test "returns a paginator with the given page and per_page as string parameters" do
      ensure_num_records(Account, 10)

      paginator = Paginator.paginate_attrs(Account, %{"page" => "2", "per_page" => "3"})
      assert paginator.pagination.current_page == 2
      assert paginator.pagination.per_page == 3

      # Try with different values to make sure the attributes are respected
      paginator = Paginator.paginate_attrs(Account, %{"page" => "3", "per_page" => "4"})
      assert paginator.pagination.current_page == 3
      assert paginator.pagination.per_page == 4
    end

    test "returns per_page but never greater than the system's _default_ maximum (100)" do
      paginator = Paginator.paginate_attrs(Account, %{"per_page" => 999})
      assert paginator.pagination.per_page == 100
    end

    test "returns per_page but never greater than the system's _defined_ maximum" do
      Application.put_env(:ewallet, :max_per_page, 20)

      paginator = Paginator.paginate_attrs(Account, %{"per_page" => 100})
      assert paginator.pagination.per_page == 20

      Application.delete_env(:ewallet, :max_per_page)
    end

    test "returns :error if given attrs.page is a negative integer" do
      result = Paginator.paginate_attrs(Account, %{"page" => -1})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.page is an invalid integer string" do
      result = Paginator.paginate_attrs(Account, %{"page" => "page what?"})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.per_page is a negative integer" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => -1})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.per_page is zero" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => 0})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.per_page is a string" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => "per page what?"})
      assert {:error, :invalid_parameter, _} = result
    end
  end

  describe "EWallet.Web.Paginator.paginate/3" do
    test "returns a EWallet.Web.Paginator with data and pagination attributes" do
      paginator = Paginator.paginate(Account, 1, 10)

      assert %Paginator{} = paginator
      assert Map.has_key?(paginator, :data)
      assert Map.has_key?(paginator, :pagination)
      assert is_list(paginator.data)
    end

    test "returns correct pagination data" do
      total = 10
      page = 2
      per_page = 3

      ensure_num_records(Account, total)
      paginator = Paginator.paginate(Account, page, per_page)

      # Assertions for paginator.pagination
      assert paginator.pagination == %{
               per_page: per_page,
               current_page: page,
               # 2nd page is not the first page
               is_first_page: false,
               # 2nd page is not the last page
               is_last_page: false
             }
    end
  end

  describe "EWallet.Web.Paginator.fetch/3" do
    test "returns a tuple of records and has_more flag" do
      ensure_num_records(Account, 10)

      {records, has_more} = Paginator.fetch(Account, 2, 5)
      assert is_list(records)
      assert is_boolean(has_more)
    end

    # 10 records with 4 per page should yield...
    # Page 1: A0, A1, A2, A3
    # Page 2: A4, A5, A6, A7
    # Page 3: A8, A9
    test "returns correct paged records" do
      ensure_num_records(Account, 10)
      per_page = 4

      query = from(a in Account, select: a.id, order_by: a.id)
      all_ids = Repo.all(query)

      # Page 1
      {records, _} = Paginator.fetch(query, 1, per_page)
      assert records == Enum.slice(all_ids, 0..3)

      # Page 2
      {records, _} = Paginator.fetch(query, 2, per_page)
      assert records == Enum.slice(all_ids, 4..7)

      # Page 3
      {records, _} = Paginator.fetch(query, 3, per_page)
      assert records == Enum.slice(all_ids, 8..9)
    end

    test "returns {_, true} if there are more records to fetch" do
      ensure_num_records(Account, 10)

      # Request page 2 out of div(10, 4) = 3
      result = Paginator.fetch(Account, 2, 4)
      assert {_, true} = result
    end

    test "returns {_, false} if there are no more records to fetch" do
      ensure_num_records(Account, 9)

      # Request page 2 out of div(10, 4) = 3
      result = Paginator.fetch(Account, 3, 3)
      assert {_, false} = result
    end
  end
end
