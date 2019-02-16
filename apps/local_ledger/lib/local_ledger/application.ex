# Copyright 2019 OmiseGO Pte Ltd
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

defmodule LocalLedger.Application do
  @moduledoc false
  alias EWalletConfig.Config

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:local_ledger)

    settings = Application.get_env(:local_ledger, :settings)
    Config.register_and_load(:local_ledger, settings)

    children =
      case Application.get_env(:local_ledger, LocalLedger.Scheduler) do
        [jobs: [_jobs]] -> [supervisor(LocalLedger.Scheduler, [])]
        _ -> []
      end

    opts = [strategy: :one_for_one, name: LocalLedger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
