defmodule AdminAPI.V1.AdminUserController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias AdminAPI.V1.UserView
  alias EWallet.AdminUserPolicy
  alias EWallet.Web.{Orchestrator, Paginator, V1.UserOverlay}
  alias EWalletDB.{User, UserQuery}

  @doc """
  Retrieves a list of admins that the current user/key has access to.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns) do
      account_uuids
      |> UserQuery.where_has_membership_in_accounts(User)
      |> Orchestrator.query(UserOverlay, attrs)
      |> respond_multiple(conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  @doc """
  Retrieves a specific admin by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => user_id}) do
    with %User{} = user <- User.get(user_id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  # Respond with a list of admins
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, UserView, :users, %{users: paged_users})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single admin
  defp respond_single(%User{} = user, conn) do
    render(conn, UserView, :user, %{user: user})
  end

  @spec permit(:all | :create | :get | :update, map(), %User{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, user) do
    Bodyguard.permit(AdminUserPolicy, action, params, user)
  end
end
