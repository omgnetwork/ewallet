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
  use EWalletConfig.SchemaCase, async: false
  import Crontab.CronExpression
  alias EWalletConfig.{ConfigTestHelper, BalanceCachingSettingsLoader}
  alias Quantum.Job

  @mock_app :mock_balance_caching_app
  @job_name :cache_all_wallets

  defmodule Scheduler do
    @moduledoc false
    use Quantum.Scheduler, otp_app: :mock_balance_caching_app
  end

  setup_all do
    {:ok, _pid} = Scheduler.start_link()
    :ok
  end

  defp init(opts) do
    Application.put_env(@mock_app, :settings, [:balance_caching_frequency])
    Application.put_env(@mock_app, :scheduler, Scheduler)

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
    setup do
      original_freq = Application.get_env(@mock_app, :balance_caching_frequency)
      :ok = Application.put_env(@mock_app, :balance_caching_frequency, original_freq)

      job =
        Scheduler.new_job()
        |> Job.set_name(@job_name)
        |> Job.set_schedule(~e[* 0 * * *])
        |> Job.set_task(fn -> :ok end)

      :ok = Scheduler.add_job(job)

      # Clean up all the side effects from each test.
      on_exit(fn ->
        :ok = Application.put_env(@mock_app, :balance_caching_frequency, original_freq)
        :ok = Scheduler.deactivate_job(@job_name)
        :ok = Scheduler.delete_job(@job_name)
      end)

      %{job: job}
    end

    test "replaces the scheduled job with the new frequency" do
      refute Scheduler.find_job(@job_name).schedule == ~e[* 9 * * *]
      {:ok, _} = init(%{"balance_caching_frequency" => "* 9 * * *"})

      assert Scheduler.find_job(@job_name).schedule == ~e[* 9 * * *]
    end

    test "returns an error if the frequency is invalid" do
      :ok = Application.delete_env(@mock_app, :balance_caching_frequency)

      {res, error} = init(%{"balance_caching_frequency" => "invalid_cron"})

      assert res == :error
      assert error == "Can't parse invalid_cron as interval minute."
    end

    test "returns a :job_not_found error if the job does not already exist" do
      :ok = Scheduler.delete_job(@job_name)

      {res, error} = init(%{"balance_caching_frequency" => "* 9 * * *"})

      assert res == :error
      assert error == :job_not_found
    end
  end
end
