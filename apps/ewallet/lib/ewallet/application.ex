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
  alias EWalletConfig.Config

  @decimal_precision 38
  @decimal_rounding :half_even

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet)

    set_decimal_context()
    settings = Application.get_env(:ewallet, :settings)
    Config.register_and_load(:ewallet, settings)

    ActivityLogger.configure(%{
      EWallet.ReleaseTasks.CLIUser => %{type: "cli_user", identifier: nil}
    })

    # List all child processes to be supervised
    children = [
      worker(EWallet.Scheduler, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWallet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp set_decimal_context do
    Decimal.get_context()
    |> Map.put(:precision, @decimal_precision)
    |> Map.put(:rounding, @decimal_rounding)
    |> Decimal.set_context()
  end
end
