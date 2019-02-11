# Copyright 2018 OmiseGO Pte Ltd
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
  alias EWallet.{AccountPolicy, AdapterHelper}
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.AccountOverlay}
  alias EWalletDB.Account

  @doc """
  Retrieves a list of accounts based on current account for users.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with {:ok, %{query: query}} <- permit(:all, conn.assigns, nil) do
      # Get all the accounts the current accessor has access to
      query
      |> Orchestrator.query(AccountOverlay, attrs)
      |> respond(conn)
    else
      error -> respond(error, conn)
    end
  end

  # DEPRECATED
  @spec descendants_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def descendants_for_account(conn, %{"id" => account_id} = _attrs) do
    with %Account{} <- Account.get(account_id) || {:error, :unauthorized} do
      respond(%Paginator{data: []}, conn)
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
         {:ok, _} <- permit(:get, conn.assigns, account),
         {:ok, account} <- Orchestrator.one(account, AccountOverlay, attrs) do
      render(conn, :account, %{account: account})
    else
      nil ->
        handle_error(conn, :account_id_not_found)

      error ->
        respond(error, conn)
    end
  end

  def get(conn, _), do: handle_error(conn, :missing_id)

  @doc """
  Creates a new account.

  The requesting user must have write permission on the given parent account.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with {:ok, _} <- permit(:create, conn.assigns, attrs),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, account} <- Account.insert(attrs),
         {:ok, account} <- Orchestrator.one(account, AccountOverlay, attrs) do
      render(conn, :account, %{account: account})
    else
      error ->
        respond(error, conn)
    end
  end

  @doc """
  Updates the account if all required parameters are provided.

  The requesting user must have write permission on the given account.
  """
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => account_id} = attrs) do
    with %Account{} = original <- Account.get(account_id) || {:error, :unauthorized},
         {:ok, _} <- permit(:update, conn.assigns, original),
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
         {:ok, _} <- permit(:update, conn.assigns, account),
         :ok <- AdapterHelper.check_adapter_status(),
         attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         %{} = saved <- Account.store_avatar(account, attrs),
         {:ok, saved} <- Orchestrator.one(saved, AccountOverlay, attrs) do
      render(conn, :account, %{account: saved})
    else
      nil ->
        handle_error(conn, :invalid_parameter)

      error ->
        respond(error, conn)
    end
  end

  def upload_avatar(conn, _), do: handle_error(conn, :invalid_parameter)

  defp respond(%Paginator{} = paginator, conn) do
    render(conn, :accounts, %{accounts: paginator})
  end

  defp respond({:error, %{authorized: false}}, conn) do
    handle_error(conn, :unauthorized)
  end

  defp respond(changeset, conn) when is_map(changeset) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond({:error, changeset}, conn) when is_map(changeset) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond({:error, code}, conn) do
    handle_error(conn, code)
  end

  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  @spec permit(:all | :create | :get | :update, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, account) do
    AccountPolicy.authorize(action, params, account)
  end
end
