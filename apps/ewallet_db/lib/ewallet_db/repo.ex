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

defmodule EWalletDB.Repo do
  use Ecto.Repo,
    otp_app: :ewallet_db,
    adapter: Ecto.Adapters.Postgres

  use ActivityLogger.ActivityRepo, repo: EWalletDB.Repo

  # Workaround an issue where ecto.migrate task won't start the app
  # thus DeferredConfig.populate is not getting called.
  #
  # Ecto itself only supports {:system, ENV_VAR} tuple, but not
  # DeferredConfig's {:system, ENV_VAR, DEFAULT} tuple nor the
  # {:apply, MFA} tuple.
  #
  # See also: https://github.com/mrluc/deferred_config/issues/2
  def init(_, config) do
    config
    |> DeferredConfig.transform_cfg()
    |> (fn updated -> {:ok, updated} end).()
  end
end
