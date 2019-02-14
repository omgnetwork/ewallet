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

defmodule EWallet.Bouncer.Permission do
  @moduledoc """
  A module containing the Permission struct
  """

  defstruct [
    :actor,
    :global_role,
    :schema,
    :types,
    :target,
    :attrs,
    :action,
    :check_account_permissions,
    :global_abilities,
    :account_abilities,
    :query,
    authorized: false,
    global_authorized: false,
    account_authorized: false
  ]
end
