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

defmodule BlockchainLedgerDB.Application do
  @moduledoc """
  The BlockchainLedgerDB data store.
  """
  use Application
  alias Appsignal.Ecto
  alias EWalletConfig.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:blockchain_ledger_db)

    settings = Application.get_env(:blockchain_ledger_db, :settings)
    Config.register_and_load(:blockchain_ledger_db, settings)

    ActivityLogger.configure(%{
      BlockchainLedgerDB.Wallet => %{type: "ethereum_wallet", identifier: :id}
    })

    :telemetry.attach(
      "appsignal-ecto",
      [:blockchain_ledger_db, :repo, :query],
      &Ecto.handle_event/4,
      nil
    )

    children = [
      supervisor(BlockchainLedgerDB.Repo, []),
      supervisor(BlockchainLedgerDB.Vault, [])
    ]

    opts = [strategy: :one_for_one, name: BlockchainLedgerDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
