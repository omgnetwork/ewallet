# Copyright 2018 OmiseGO Pte Ltd
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
  alias Crontab.CronExpression.Parser

  @job_name :cache_all_wallets

  @spec load(atom()) :: :ok | {:error, :scheduler_config_not_found}
  def load(app) do
    namespace = Application.get_env(app, :namespace)
    config = Module.concat(namespace, Config)
    scheduler = Module.concat(namespace, Scheduler)

    :ok = scheduler.delete_job(@job_name)

    case config.read_scheduler_config() do
      [] ->
        {:error, :scheduler_config_not_found}

      config ->
        scheduler
        |> build_job(config)
        |> schedule_job(scheduler)
    end
  end

  defp build_job(scheduler, config) do
    config
    |> Keyword.get(@job_name)
    |> Enum.reduce(scheduler.new_job(), fn
      {:schedule, cron_string}, job ->
        Map.put(job, :schedule, Parser.parse!(cron_string))

      {key, value}, job ->
        Map.put(job, key, value)
    end)
    |> Map.put(:name, @job_name)
  end

  defp schedule_job(job, scheduler) do
    :ok = scheduler.deactivate_job(@job_name)
    :ok = scheduler.delete_job(@job_name)
    :ok = scheduler.add_job(job)
    :ok = scheduler.activate_job(@job_name)
  end
end
