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

defmodule AdminAPI.V1.AccountHelper do
  @moduledoc """
  Simple helper module to access accounts from controllers.
  """
  alias EWalletDB.{Key, User, Helpers.Preloader}

  @spec get_accessible_account_uuids(%{admin_user: %User{}} | %{key: %Key{}}) :: [String.t()]
  def get_accessible_account_uuids(%{admin_user: admin_user}) do
    Preloader.preload(admin_user, [:accounts]).accounts
    |> Enum.map(fn account -> account.uuid end)
  end
end
