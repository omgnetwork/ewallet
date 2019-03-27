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

defmodule EWalletConfig.SchemaCase do
  @moduledoc """
  This module defines common behaviors shared for EWalletConfig schema tests.
  """
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox
  alias EWalletConfig.Repo

  setup do
    # Restarts `EWalletConfig.Config` so it does not hang on to a DB connection for too long.
    _ = Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
    _ = Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

    _ = Sandbox.checkout(Repo)
    _ = Sandbox.checkout(ActivityLogger.Repo)
  end
end
