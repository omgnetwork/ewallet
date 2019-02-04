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

defmodule EWalletConfig.BalanceCachingSettingsLoaderTest do
  use EWalletConfig.SchemaCase, async: true
  alias Crontab.CronExpression.Parser
  alias EWalletConfig.{ConfigTestHelper, BalanceCachingSettingsLoader}

  @mock_app :mock_balance_caching_app

  #
  # Mock modules to avoid unnecessary coupling with `LocalLedger`.
  #

  defmodule Config do
    def read_scheduler_config do
      [
        cache_all_wallets: [
          schedule: Application.get_env(:mock_balance_caching_app, :balance_caching_frequency),
          task: {__MODULE__, :target_task, []},
          run_strategy: {Quantum.RunStrategy.Random, :cluster}
        ]
      ]
    end

    def target_task, do: :noop
  end

  defmodule Scheduler do
    @moduledoc false
    use Quantum.Scheduler, otp_app: :mock_balance_caching_app
  end

  #
  # Test implementations
  #

  setup do
    {:ok, _pid} = Scheduler.start_link()
    :ok
  end

  defp init(opts) do
    Application.put_env(@mock_app, :settings, [:balance_caching_frequency])
    Application.put_env(@mock_app, :scheduler, Scheduler)
    Application.put_env(@mock_app, :scheduler_config, Config)

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [@mock_app],
      opts
    )

    BalanceCachingSettingsLoader.load(@mock_app)
  end

  describe "load/1" do
    test "loads the caching frequency into the app env" do
      schedule = "* 2 * * *"
      refute Application.get_env(@mock_app, :balance_caching_frequency) == schedule

      init(%{"balance_caching_frequency" => schedule})
      assert Application.get_env(@mock_app, :balance_caching_frequency) == schedule
    end

    test "replaces the scheduled job with the new frequency" do
      schedule = "* 3 * * *"
      assert Scheduler.find_job(:cache_all_wallets) == nil

      init(%{"balance_caching_frequency" => schedule})

      assert Scheduler.find_job(:cache_all_wallets).schedule == Parser.parse!(schedule)
    end
  end
end
