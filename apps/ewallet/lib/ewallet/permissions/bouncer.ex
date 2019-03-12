# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.Bouncer do
  @moduledoc """
  The entry point module to the permissions logic.
  """
  alias EWallet.Bouncer.{
    Helper,
    Permission,
    DispatchConfig,
    Dispatcher,
    GlobalBouncer,
    AccountBouncer
  }

  alias EWalletDB.{GlobalRole, Role}

  def bounce(actor, permission, config \\ %{}) do
    config = prepare_config(config)

    case Helper.get_actor(actor) do
      nil ->
        set_authorized(permission)

      actor ->
        case GlobalBouncer.bounce(%{permission | actor: actor}, config) do
          %Permission{global_authorized: true} = permission ->
            # The actor has global access so we don't check the account permissions.
            {:ok, %{permission | authorized: true}}

          %Permission{global_authorized: false, check_account_permissions: true} = permission ->
            # The actor does not have global access, but can check account permissions
            # so we check them!
            permission
            |> AccountBouncer.bounce(config)
            |> set_authorized()

          permission ->
            # The actor does not have global access and is not allowed to check account permissions
            # so we skip and return false
            {:error, %{permission | authorized: false}}
        end
    end
  end

  @spec scoped_query(EWallet.Bouncer.Permission.t()) :: any()
  def scoped_query(%Permission{authorized: true} = permission) do
    Dispatcher.scoped_query(permission)
  end

  def scoped_query(_), do: nil

  defp prepare_config(config) do
    config
    |> Map.put_new(:dispatch_config, DispatchConfig)
    |> Map.put_new(:global_permissions, GlobalRole.global_role_permissions())
    |> Map.put_new(:account_permissions, Role.account_role_permissions())
  end

  defp set_authorized(%{account_authorized: true} = permission) do
    {:ok, %{permission | authorized: true}}
  end

  defp set_authorized(permission) do
    {:error, %{permission | authorized: false}}
  end
end
