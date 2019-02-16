# Copyright 2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.AccountController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.{AccountPolicy, AdapterHelper}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.AccountOverlay}
  alias EWalletDB.Account

  @doc """
  Retrieves a list of accounts based on current account for users.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns) do
      # Get all the accounts the current accessor has access to
      Account
      |> Account.where_in(account_uuids)
      |> Orchestrator.query(AccountOverlay, attrs)
      |> respond(conn)
    else
      error -> respond(error, conn)
    end
  end

  @spec descendants_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def descendants_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account.id),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      # Get all users since everyone can access them
      Account
      |> Account.where_in(descendant_uuids)
      |> Orchestrator.query(AccountOverlay, attrs)
      |> respond(conn)
    else
      error -> respond(error, conn)
    end
  end

  def descendants_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Retrieves a specific account by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id} = attrs) do
    with %Account{} = account <- Account.get_by(id: id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, account.id),
         {:ok, account} <- Orchestrator.one(account, AccountOverlay, attrs) do
      render(conn, :account, %{account: account})
    else
      {:error, code} ->
        handle_error(conn, code)

      nil ->
        handle_error(conn, :account_id_not_found)
    end
  end

  def get(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Creates a new account.

  The requesting user must have write permission on the given parent account.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    parent =
      if attrs["parent_id"] do
        Account.get_by(id: attrs["parent_id"])
      else
        Account.get_master_account()
      end

    with :ok <- permit(:create, conn.assigns, parent.id),
         attrs <- Map.put(attrs, "parent_uuid", parent.uuid),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, account} <- Account.insert(attrs),
         {:ok, account} <- Orchestrator.one(account, AccountOverlay, attrs) do
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
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => account_id} = attrs) do
    with %Account{} = original <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, original.id),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, updated} <- Account.update(original, attrs),
         {:ok, updated} <- Orchestrator.one(updated, AccountOverlay, attrs) do
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
  @spec upload_avatar(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def upload_avatar(conn, %{"id" => id, "avatar" => _} = attrs) do
    with %Account{} = account <- Account.get(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, account.id),
         :ok <- AdapterHelper.check_adapter_status(),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         %{} = saved <- Account.store_avatar(account, attrs),
         {:ok, saved} <- Orchestrator.one(saved, AccountOverlay, attrs) do
      render(conn, :account, %{account: saved})
    else
      nil ->
        handle_error(conn, :invalid_parameter)

      changeset when is_map(changeset) ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, changeset} when is_map(changeset) ->
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

  @spec permit(:all | :create | :get | :update, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, account_id) do
    Bodyguard.permit(AccountPolicy, action, params, account_id)
  end
end
