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

defmodule EWallet.Bouncer.APIKeyScope do
  @moduledoc """
  Permission scoping module for API keys.
  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  import Ecto.Query
  alias EWallet.Bouncer.Permission
  alias EWalletDB.{APIKey, Key, User}

  @spec scoped_query(EWallet.Bouncer.Permission.t()) :: nil | Ecto.Query.t()
  def scoped_query(%Permission{
        actor: actor,
        global_abilities: global_abilities,
        account_abilities: account_abilities
      }) do
    do_scoped_query(actor, global_abilities) || do_scoped_query(actor, account_abilities)
  end

  defp do_scoped_query(_actor, %{api_keys: :global}) do
    APIKey.query_all()
  end

  defp do_scoped_query(%User{} = user, %{api_keys: :self}) do
    APIKey.query_all()
    |> where([a], a.creator_user_uuid == ^user.uuid)
  end

  defp do_scoped_query(%Key{} = key, %{api_keys: :self}) do
    APIKey.query_all()
    |> where([a], a.creator_key_uuid == ^key.uuid)
  end

  defp do_scoped_query(_, _) do
    nil
  end
end
