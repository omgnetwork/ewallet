defmodule AdminAPI.V1.CategoryController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.CategoryPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias EWalletDB.Category

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that should be preloaded.
  # Note that these values *must be in the schema associations*.
  @preload_fields [:accounts]

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # If the request provides different names, map it via `@mapped_fields` first.
  @search_fields [:id, :name, :description]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :name, :description, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of categories.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      categories =
        Category
        |> Preloader.to_query(@preload_fields)
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
    with :ok <- permit(:get, conn.assigns, id),
         %Category{} = category <- Category.get_by(id: id),
         {:ok, category} <- Preloader.preload_one(category, @preload_fields) do
      render(conn, :category, %{category: category})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :category_id_not_found)
    end
  end

  @doc """
  Creates a new category.
  """
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         {:ok, category} <- Category.insert(attrs),
         {:ok, category} <- Preloader.preload_one(category, @preload_fields) do
      render(conn, :category, %{category: category})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates the category if all required parameters are provided.
  """
  def update(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:update, conn.assigns, id),
         %Category{} = original <- Category.get(id) || {:error, :category_id_not_found},
         {:ok, updated} <- Category.update(original, attrs),
         {:ok, updated} <- Preloader.preload_one(updated, @preload_fields) do
      render(conn, :category, %{category: updated})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Soft-deletes an existing category by its id.
  """
  def delete(conn, %{"id" => id}) do
    with %Category{} = category <- Category.get(id) || {:error, :category_id_not_found},
         {:ok, deleted} = Category.delete(category),
         {:ok, deleted} <- Preloader.preload_one(deleted, @preload_fields) do
      render(conn, :category, %{category: deleted})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def delete(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec permit(:all | :create | :get | :update, any(), any()) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, %{admin_user: admin_user}, category_id) do
    Bodyguard.permit(CategoryPolicy, action, admin_user, category_id)
  end

  defp permit(action, %{key: key}, category_id) do
    Bodyguard.permit(CategoryPolicy, action, key, category_id)
  end
end
