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

defmodule EWallet.Bouncer.ExportTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWallet.Bouncer.{UserTarget}
  alias EWalletDB.{User, Export}

  def get_owner_uuids(%Export{user_uuid: user_uuid, key_uuid: key_uuid}) do
    [user_uuid || key_uuid]
  end

  def get_target_types do
    [:exports]
  end

  def get_target_type(%Export{}), do: :exports

  def get_target_accounts(%Export{user_uuid: user_uuid}, dispatch_config)
      when not is_nil(user_uuid) do
    [uuid: user_uuid]
    |> User.get_by()
    |> UserTarget.get_target_accounts(dispatch_config)
  end

  def get_target_accounts(%Export{}, _dispatch_config), do: []
end
