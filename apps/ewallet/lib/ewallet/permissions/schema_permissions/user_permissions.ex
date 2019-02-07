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

defmodule EWallet.SchemaPermissions.UserPermissions do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWalletDB.User
  alias EWalletDB.Helpers.Preloader

  def get_owner_uuids(%User{uuid: uuid}) do
    [uuid]
  end

  def get_target_type(%User{is_admin: true}) do
    :admin_users
  end

  def get_target_type(%User{is_admin: false}) do
    :end_users
  end

  def get_actor_accounts(%User{is_admin: true} = actor) do
    actor = Preloader.preload(actor, [:accounts])
    actor.accounts
  end

  def get_actor_accounts(%User{is_admin: false} = actor) do
    actor = Preloader.preload(actor, [:linked_accounts])
    actor.linked_accounts
  end

  def get_target_accounts(%User{is_admin: true} = target) do
    target.accounts
  end

  def get_target_accounts(%User{is_admin: false} = target) do
    target = Preloader.preload(target, [:linked_accounts])
    target.linked_accounts
  end
end
