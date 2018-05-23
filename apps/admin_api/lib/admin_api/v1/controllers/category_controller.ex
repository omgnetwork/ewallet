defmodule AdminAPI.V1.CategoryController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.CategoryPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.Category

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # If the request provides different names, map it via `@mapped_fields` first.
  @search_fields [:id, :name, :description]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :name, :description, :inserted_at, :updated_at]

  defp permit(action, user_id, category_id) do
    Bodyguard.permit(CategoryPolicy, action, user_id, category_id)
  end

  @doc """
  Retrieves a list of categories.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns.user.id, nil) do
      categories =
        Category
        |> SearchParser.to_query(attrs, @search_fields, @mapped_fields)
        |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
        |> Paginator.paginate_attrs(attrs)

      case categories do
        %Paginator{} = paginator ->
          render(conn, :categories, %{categories: paginator})

        {:error, code, description} ->
          handle_error(conn, code, description)
      end
    else
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Retrieves a specific category by its id.
  """
  def get(conn, %{"id" => id}) do
    with :ok <- permit(:get, conn.assigns.user.id, nil),
         %Category{} = category <- Category.get_by(id: id) do
      render(conn, :category, %{category: category})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :category_id_not_found)
    end
  end

  # @doc """
  # Creates a new account.

  # The requesting user must have write permission on the given parent account.
  # """
  # def create(conn, attrs) do
  #   parent =
  #     if attrs["parent_id"] do
  #       Account.get_by(id: attrs["parent_id"])
  #     else
  #       Account.get_master_account()
  #     end

  #   with :ok <- permit(:create, conn.assigns.user.id, parent.id),
  #        attrs <- Map.put(attrs, "parent_uuid", parent.uuid),
  #        {:ok, account} <- Account.insert(attrs) do
  #     render(conn, :account, %{account: account})
  #   else
  #     {:error, %{} = changeset} ->
  #       handle_error(conn, :invalid_parameter, changeset)

  #     {:error, code} ->
  #       handle_error(conn, code)
  #   end
  # end

  # @doc """
  # Updates the account if all required parameters are provided.

  # The requesting user must have write permission on the given account.
  # """
  # def update(conn, %{"id" => account_id} = attrs) do
  #   with :ok <- permit(:update, conn.assigns.user.id, account_id),
  #        %{} = original <- Account.get(account_id) || {:error, :account_id_not_found},
  #        {:ok, updated} <- Account.update(original, attrs) do
  #     render(conn, :account, %{account: updated})
  #   else
  #     {:error, %{} = changeset} ->
  #       handle_error(conn, :invalid_parameter, changeset)

  #     {:error, code} ->
  #       handle_error(conn, code)
  #   end
  # end

  # def update(conn, _), do: handle_error(conn, :invalid_parameter)
end
