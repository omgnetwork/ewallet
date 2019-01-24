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

defmodule EWallet.ReleaseTasks.InitDB do
  @moduledoc """
  A release task that performs database initialization, namely database creation and migration.

  This release task can also be run on initialized database in order to migrate up to the latest
  database schema.
  """
  use EWallet.ReleaseTasks
  alias Ecto.Migrator
  alias EWallet.CLI

  @start_apps [:crypto, :ssl, :postgrex, :ecto]
  @apps [:ewallet_config, :activity_logger, :ewallet_db, :local_ledger_db]

  def run do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@apps, &initdb/1)
    :init.stop()
  end

  defp initdb(app_name) do
    :ok = Application.load(app_name)
    repos = Application.get_env(app_name, :ecto_repos, [])

    Enum.each(repos, &run_create_for/1)
    Enum.each(repos, & &1.start_link(pool_size: 1))
    Enum.each(repos, &run_migrations_for/1)
  end

  defp run_create_for(repo) do
    case repo.__adapter__.storage_up(repo.config) do
      :ok ->
        CLI.info("The database for #{inspect(repo)} has been created")

      {:error, :already_up} ->
        CLI.info("The database for #{inspect(repo)} has already been created")

      {:error, term} when is_binary(term) ->
        CLI.error("The database for #{inspect(repo)} couldn't be created: #{term}")

      {:error, term} ->
        CLI.error("The database for #{inspect(repo)} couldn't be created: #{inspect(term)}")
    end
  end

  defp run_migrations_for(repo) do
    migrations_path = priv_path_for(repo, "migrations")
    CLI.info("Running migration for #{inspect(repo)}...")
    Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
