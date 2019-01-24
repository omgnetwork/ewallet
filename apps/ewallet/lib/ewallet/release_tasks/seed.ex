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

defmodule EWallet.ReleaseTasks.Seed do
  @moduledoc """
  A release task that performs database seeding.
  """
  use EWallet.ReleaseTasks
  alias EWallet.Seeder.CLI

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :cloak,
    :ewallet,
    :ewallet_db,
    :ewallet_config,
    :activity_logger
  ]
  @std_spec [{:ewallet_config, :seeds_settings}, {:ewallet_db, :seeds}]
  @e2e_spec [{:ewallet_config, :seeds_settings}, {:ewallet_db, :seeds_test}]
  @sample_spec [
    {:ewallet_config, :seeds_settings},
    {:ewallet_db, :seeds},
    {:ewallet_db, :seeds_sample}
  ]
  @settings_spec [{:ewallet_config, :seeds_settings}]

  def run, do: seed_with(@std_spec)
  def run_e2e, do: seed_with(@e2e_spec)
  def run_sample, do: seed_with(@sample_spec)
  def run_settings, do: seed_with(@settings_spec)
  def run_settings_no_stop, do: seed_with(@settings_spec, false)

  defp seed_with(spec, stop \\ true) do
    _ = Enum.each(@start_apps, &Application.ensure_all_started/1)
    _ = Enum.each(spec, &ensure_app_started/1)
    _ = CLI.run(spec, true)

    if stop, do: :init.stop(), else: :ok
  end
end
