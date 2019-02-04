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

defmodule EWalletConfig.BalanceCachingSettingsLoader do
  @moduledoc """
  Maps the DB settings to the configuration needed for balance caching mechanism.
  """
  require Logger
  alias Crontab.CronExpression
  alias Crontab.CronExpression.Parser
  alias Quantum.Job

  @job_name :cache_all_wallets

  @spec load(atom()) :: :ok | {:error, :scheduler_config_not_found}
  def load(app) do
    scheduler = Application.get_env(app, :scheduler)
    frequency = Application.get_env(app, :balance_caching_frequency)

    update_frequency(frequency, scheduler)
  end

  defp update_frequency(nil, _scheduler) do
    {:error, :frequency_not_found}
  end

  defp update_frequency(frequency, scheduler) when is_binary(frequency) do
    case Parser.parse(frequency) do
      {:ok, cron_expression} -> update_frequency(cron_expression, scheduler)
      {:error, _} = error -> error
    end
  end

  defp update_frequency(%CronExpression{} = expression, scheduler) do
    case scheduler.find_job(@job_name) do
      nil ->
        {:error, :job_not_found}

      job ->
        job
        |> Job.set_schedule(expression)
        |> reschedule(scheduler)
    end
  end

  defp reschedule(job, scheduler) do
    :ok = scheduler.deactivate_job(job.name)
    :ok = scheduler.delete_job(job.name)
    :ok = scheduler.add_job(job)
    :ok = scheduler.activate_job(job.name)

    {:ok, job}
  end
end
