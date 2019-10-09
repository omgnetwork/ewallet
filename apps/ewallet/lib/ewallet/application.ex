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

defmodule EWallet.Application do
  @moduledoc false
  use Application
  alias EWallet.BlockchainHelper
  alias EWalletConfig.Config

  @decimal_precision 38
  @decimal_rounding :half_even

  @rootchain_identifier BlockchainHelper.rootchain_identifier()

  def start(_type, _args) do
    _ = DeferredConfig.populate(:ewallet)
    _ = set_decimal_context()

    _ =
      ActivityLogger.configure(%{
        EWallet.ReleaseTasks.CLIUser => %{type: "cli_user", identifier: nil}
      })

    children = [
      # Quantum scheduler
      {EWallet.Scheduler, []},

      # Transaction tracker supervisor and registry
      {Registry, keys: :unique, name: EWallet.TransactionTrackerRegistry},
      {DynamicSupervisor, name: EWallet.TransactionTrackerSupervisor, strategy: :one_for_one},
      Supervisor.child_spec(
        {EWallet.AddressTracker, [blockchain_identifier: @rootchain_identifier]},
        id: EWallet.AddressTracker
      ),
      Supervisor.child_spec(
        {EWallet.DepositWalletPoolingTracker, [blockchain_identifier: @rootchain_identifier]},
        id: EWallet.DepositWalletPoolingTracker
      )
    ]

    start_result = Supervisor.start_link(children, name: EWallet.Supervisor, strategy: :one_for_one)

    # The config may start/stop some processes (e.g. AddressTracker), so we register
    # and load the configs only after the supervisor and all its children are started.
    settings = Application.get_env(:ewallet, :settings)
    _ = Config.register_and_load(:ewallet, settings)

    start_result
  end

  defp set_decimal_context do
    Decimal.get_context()
    |> Map.put(:precision, @decimal_precision)
    |> Map.put(:rounding, @decimal_rounding)
    |> Decimal.set_context()
  end
end
