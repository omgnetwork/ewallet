defmodule EWallet.ReleaseTasks do
  @moduledoc """
  Provides a task for use within release.
  """
  alias Ecto.Migrator
  alias EWallet.Seeder.CLI

  #
  # Seed
  #

  @seed_start_apps [:crypto, :ssl, :postgrex, :ecto, :cloak]
  @seed_std_spec [{:ewallet_db, :seeds}]
  @seed_e2e_spec [{:ewallet_db, :seeds_test}]

  def seed, do: seed_with(@seed_std_spec)
  def seed_e2e, do: seed_with(@seed_e2e_spec)

  defp seed_with(spec) do
    Enum.each(@seed_start_apps, &Application.ensure_all_started/1)
    Enum.each(spec, &ensure_started/1)
    _ = CLI.run(spec)
    :init.stop()
  end

  defp ensure_started({app_name, _}) do
    case Application.ensure_all_started(app_name) do
      {:ok, _} ->
        repos = Application.get_env(app_name, :ecto_repos, [])
        Enum.each(repos, & &1.start_link(pool_size: 1))

      _ ->
        nil
    end
  end

  #
  # Initdb
  #

  @initdb_start_apps [:crypto, :ssl, :postgrex, :ecto]
  @initdb_apps [:ewallet_db, :local_ledger_db]

  def initdb do
    Enum.each(@initdb_start_apps, &Application.ensure_all_started/1)
    Enum.each(@initdb_apps, &initdb/1)
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
        IO.puts("The database for #{inspect(repo)} has been created")

      {:error, :already_up} ->
        IO.puts("The database for #{inspect(repo)} has already been created")

      {:error, term} when is_binary(term) ->
        IO.puts("The database for #{inspect(repo)} couldn't be created: #{term}")

      {:error, term} ->
        IO.puts("The database for #{inspect(repo)} couldn't be created: #{inspect(term)}")
    end
  end

  defp run_migrations_for(repo) do
    migrations_path = priv_path_for(repo, "migrations")
    IO.puts("Running migration for #{inspect(repo)}...")
    Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
