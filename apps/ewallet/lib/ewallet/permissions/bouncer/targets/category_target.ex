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

defmodule EWallet.Bouncer.CategoryTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.{Category, Helpers.Preloader}

  @spec get_owner_uuids(Category.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(_) do
    []
  end

  @spec get_target_types() :: [:categories]
  def get_target_types(), do: [:categories]

  @spec get_target_type(Category.t()) :: :categories
  def get_target_type(_), do: :categories

  # WARNING: This will work only with the hardcoded roles that were originaly defined.
  # If the roles are changed, especially if a role other than super_admin gains access to
  # category creation with an `accounts` scope, this will fail.
  @spec get_target_accounts(Category.t(), any()) :: [Account.t()]
  def get_target_accounts(%Category{} = category, _dispatch_config) do
    Preloader.preload(category, [:accounts]).accounts
  end
end
