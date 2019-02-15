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

defmodule EWallet.Bouncer.KeyTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWallet.Bouncer.Permission
  alias EWalletDB.{Key, Helpers.Preloader}

  def get_owner_uuids(%Key{uuid: uuid}) do
    [uuid]
  end

  def get_query_actor_records(%Permission{type: :accounts, actor: actor}) do
    Ecto.assoc(actor, :accounts)
  end

  def get_query_actor_records(%Permission{type: :memberships, actor: actor}) do
    Ecto.assoc(actor, :memberships)
  end

  def get_target_accounts(%Key{} = key) do
    get_actor_accounts(key)
  end

  def get_actor_accounts(%Key{} = key) do
    Preloader.preload(key, [:accounts]).accounts
  end
end
