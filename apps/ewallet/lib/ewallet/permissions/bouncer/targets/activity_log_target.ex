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

defmodule EWallet.Bouncer.ActivityLogTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias ActivityLogger.ActivityLog

  def get_owner_uuids(activity_log) do
    activity_log.originator_uuid
  end

  def get_target_types do
    [:activity_logs]
  end

  def get_target_type(%ActivityLog{}), do: :activity_logs

  def get_target_accounts(%ActivityLog{} = _activity_log) do
    []
  end
end
