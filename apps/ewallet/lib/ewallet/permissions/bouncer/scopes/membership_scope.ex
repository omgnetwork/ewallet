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

defmodule EWallet.Bouncer.MembershipScope do
  @moduledoc """
  Permission scoping module for memberships.
  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.Permission
  alias EWalletDB.{Membership, User, Key}

  @spec scoped_query(EWallet.Bouncer.Permission.t()) ::
          EWalletDB.Membership | nil | Ecto.Query.t()
  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  defp do_scoped_query(_actor, %{memberships: :global}) do
    Membership
  end

  defp do_scoped_query(%User{is_admin: true} = user, %{memberships: :accounts}) do
    where(Membership, [m], m.user_uuid == ^user.uuid)
  end

  defp do_scoped_query(%Key{} = key, %{memberships: :accounts}) do
    where(Membership, [m], m.key_uuid == ^key.uuid)
  end

  defp do_scoped_query(_, _) do
    nil
  end
end
