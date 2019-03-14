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

defmodule AdminAPI.V1.PermissionController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{GlobalRolePolicy, RolePolicy}
  alias EWalletDB.{GlobalRole, Role}

  @doc """
  Retrieves a list of all permissions.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, _attrs) do
    with {:ok, _} <- authorize_global_role(:all, conn.assigns),
         {:ok, _} <- authorize_account_role(:all, conn.assigns) do
      permissions = %{
        global_roles: GlobalRole.global_role_permissions(),
        account_roles: Role.account_role_permissions()
      }

      render(conn, :permissions, permissions)
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  @spec authorize_global_role(:all, map()) :: any()
  defp authorize_global_role(action, actor) do
    GlobalRolePolicy.authorize(action, actor, nil)
  end

  @spec authorize_account_role(:all, map()) :: any()
  defp authorize_account_role(action, actor) do
    RolePolicy.authorize(action, actor, nil)
  end
end
