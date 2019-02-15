# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule ExternalLedgerDB.Application do
  @moduledoc """
  The ExternalLedgerDB data store.
  """
  use Application
  alias Appsignal.Ecto
  alias EWalletConfig.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:external_ledger_db)
    DeferredConfig.populate(:ethereumex)

    settings = Application.get_env(:external_ledger_db, :settings)
    Config.register_and_load(:external_ledger_db, settings)

    ActivityLogger.configure(%{
      ExternalLedgerDB.Wallet => %{type: "external_ledger_wallet", identifier: :id}
    })

    :telemetry.attach(
      "appsignal-ecto",
      [:external_ledger_db, :repo, :query],
      &Ecto.handle_event/4,
      nil
    )

    children = [
      supervisor(ExternalLedgerDB.Repo, []),
      supervisor(ExternalLedgerDB.Vault, [])
    ]

    opts = [strategy: :one_for_one, name: ExternalLedgerDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
