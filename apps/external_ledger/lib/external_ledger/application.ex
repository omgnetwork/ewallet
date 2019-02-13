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

defmodule ExternalLedger.Application do
  @moduledoc """
  The ExternalLedger data store.
  """
  use Application
  alias Appsignal.Ecto
  alias EWalletConfig.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:external_ledger)

    settings = Application.get_env(:external_ledger, :settings)
    Config.register_and_load(:external_ledger, settings)

    ActivityLogger.configure(%{
      ExternalLedger.Wallet => %{type: "external_ledger_wallet", identifier: :id}
    })

    :telemetry.attach(
      "appsignal-ecto",
      [:external_ledger, :repo, :query],
      &Ecto.handle_event/4,
      nil
    )

    children = [
      supervisor(ExternalLedger.Repo, []),
      supervisor(ExternalLedger.Vault, [])
    ]

    opts = [strategy: :one_for_one, name: ExternalLedger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
