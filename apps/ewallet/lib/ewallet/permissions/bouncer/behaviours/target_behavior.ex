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

defmodule EWallet.Bouncer.TargetBehaviour do
  @moduledoc """
  A behavior defining the needed functions for a schema permissions module.
  """
  alias EWalletDB.Account

  # Gets all the uuids owning the given target.
  @callback get_owner_uuids(any()) :: [any()]

  # Gets the appropriate type or subtypes for the target.
  @callback get_target_type(any()) :: atom()

  # Gets all the accounts that have power over the target.
  @callback get_target_accounts(any(), map()) :: [Account.t()]
end
