defmodule AdminAPI.V1.AccountController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
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
  Retrieves a list of accounts.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      accounts =
        Account
        |> Preloader.to_query(@preload_fields)
        |> SearchParser.to_query(attrs, @search_fields, @mapped_fields)
        |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
        |> Paginator.paginate_attrs(attrs)

      case accounts do
        %Paginator{} = paginator ->
          render(conn, :accounts, %{accounts: paginator})

        {:error, code, description} ->
          handle_error(conn, code, description)
      end
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :account_id_not_found)
    end
  end

  @doc """
  Retrieves a specific account by its id.
  """
  def get(conn, %{"id" => id}) do
    with :ok <- permit(:get, conn.assigns, id),
         %Account{} = account <- Account.get_by(id: id),
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
    with :ok <- permit(:update, conn.assigns, account_id),
         %{} = original <- Account.get(account_id) || {:error, :account_id_not_found},
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
    with :ok <- permit(:update, conn.assigns, id),
         %{} = account <- Account.get(id) || {:error, :account_id_not_found},
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

  @spec permit(:all | :create | :get | :update, map(), String.t()) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, %{admin_user: admin_user}, account_id) do
    Bodyguard.permit(AccountPolicy, action, admin_user, account_id)
  end

  defp permit(action, %{key: key}, account_id) do
    Bodyguard.permit(AccountPolicy, action, key, account_id)
  end
end
