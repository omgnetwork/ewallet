defmodule AdminAPI.V1.AccountController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.AccountPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias EWalletDB.Account

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that should be preloaded.
  # Note that these values *must be in the schema associations*.
  @preload_fields [:categories]

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # If the request provides different names, map it via `@mapped_fields` first.
  @search_fields [:id, :name, :description]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :name, :description, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of accounts based on current account for users.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns) do
      # Get all the accounts the current accessor has access to
      Account
      |> Account.where_in(account_uuids)
      |> Preloader.to_query(@preload_fields)
      |> SearchParser.to_query(attrs, @search_fields, @mapped_fields)
      |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
      |> Paginator.paginate_attrs(attrs)
      |> respond(conn)
    else
      error -> respond(error, conn)
      nil -> respond(conn, :account_id_not_found)
    end
  end

  def descendants_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account.id),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      # Get all users since everyone can access them
      Account
      |> Account.where_in(descendant_uuids)
      |> SearchParser.to_query(attrs, @search_fields)
      |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
      |> Paginator.paginate_attrs(attrs)
      |> respond(conn)
    else
      error -> respond(error, conn)
    end
  end

  def descendants_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves a specific account by its id.
  """
  def get(conn, %{"id" => id}) do
    with %Account{} = account <- Account.get_by(id: id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, account.id),
         {:ok, account} <- Preloader.preload_one(account, @preload_fields) do
      render(conn, :account, %{account: account})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :account_id_not_found)
    end
  end

  @doc """
  Creates a new account.

  The requesting user must have write permission on the given parent account.
  """
  def create(conn, attrs) do
    parent =
      if attrs["parent_id"] do
        Account.get_by(id: attrs["parent_id"])
      else
        Account.get_master_account()
      end

    with :ok <- permit(:create, conn.assigns, parent.id),
         attrs <- Map.put(attrs, "parent_uuid", parent.uuid),
         {:ok, account} <- Account.insert(attrs),
         {:ok, account} <- Preloader.preload_one(account, @preload_fields) do
      render(conn, :account, %{account: account})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates the account if all required parameters are provided.

  The requesting user must have write permission on the given account.
  """
  def update(conn, %{"id" => account_id} = attrs) do
    with %Account{} = original <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, original.id),
         {:ok, updated} <- Account.update(original, attrs),
         {:ok, updated} <- Preloader.preload_one(updated, @preload_fields) do
      render(conn, :account, %{account: updated})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Uploads an image as avatar for a specific account.
  """
  def upload_avatar(conn, %{"id" => id, "avatar" => _} = attrs) do
    with %Account{} = account <- Account.get(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, account.id),
         %{} = saved <- Account.store_avatar(account, attrs),
         {:ok, saved} <- Preloader.preload_one(saved, @preload_fields) do
      render(conn, :account, %{account: saved})
    else
      nil ->
        handle_error(conn, :invalid_parameter)

      changeset when is_map(changeset) ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  def upload_avatar(conn, _), do: handle_error(conn, :invalid_parameter)

  defp respond(%Paginator{} = paginator, conn) do
    render(conn, :accounts, %{accounts: paginator})
  end

  defp respond({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @spec permit(:all | :create | :get | :update, map(), String.t()) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, account_id) do
    Bodyguard.permit(AccountPolicy, action, params, account_id)
  end
end
