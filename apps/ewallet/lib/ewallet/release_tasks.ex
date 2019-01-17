defmodule EWallet.ReleaseTasks do
  @moduledoc """
  Provides a task for use within release.
  """
  alias Ecto.Migrator
  alias EWallet.Seeder.CLI
  alias EWalletConfig.Config
  alias ActivityLogger.System

  #
  # Utils
  #

  defp ensure_app_started({app_name, _}), do: ensure_app_started(app_name)

  defp ensure_app_started(app_name) do
    case Application.ensure_all_started(app_name) do
      {:ok, _} ->
        repos = Application.get_env(app_name, :ecto_repos, [])
        Enum.each(repos, & &1.start_link(pool_size: 1))

      _ ->
        nil
    end
  end

  defp give_up do
    IO.puts("Error: unknown error occured in release tasks. This is probably a bug.")
    IO.puts("Please file a bug report at https://github.com/omisego/ewallet/issues/new")
    :init.stop(1)
  end

  #
  # Seed
  #

  @seed_start_apps [:crypto, :ssl, :postgrex, :ecto, :cloak, :ewallet]
  @seed_std_spec [{:ewallet_config, :seeds_settings}, {:ewallet_db, :seeds}]
  @seed_e2e_spec [{:ewallet_config, :seeds_settings}, {:ewallet_db, :seeds_test}]
  @seed_sample_spec [
    {:ewallet_config, :seeds_settings},
    {:ewallet_db, :seeds},
    {:ewallet_db, :seeds_sample}
  ]

  def seed, do: seed_with(@seed_std_spec)
  def seed_e2e, do: seed_with(@seed_e2e_spec)
  def seed_sample, do: seed_with(@seed_sample_spec)

  defp seed_with(spec) do
    Enum.each(@seed_start_apps, &Application.ensure_all_started/1)
    Enum.each(spec, &ensure_app_started/1)
    _ = CLI.run(spec, true)
    :init.stop()
  end

  #
  # Initdb
  #

  @initdb_start_apps [:crypto, :ssl, :postgrex, :ecto]
  @initdb_apps [:ewallet_config, :activity_logger, :ewallet_db, :local_ledger_db]

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

  #
  # Config
  #

  @config_start_apps [:crypto, :ssl, :postgrex, :ecto, :cloak, :ewallet]
  @config_apps [:activity_logger, :ewallet_config]

  def config_base64 do
    case :init.get_plain_arguments() do
      [key, value] ->
        config_base64(key, value)

      _ ->
        give_up()
    end
  end

  defp config_base64(k, v) when is_list(k) do
    case Base.decode64(to_string(k)) do
      {:ok, key} ->
        config_base64(key, v)

      _ ->
        give_up()
    end
  end

  defp config_base64(k, v) when is_list(v) do
    case Base.decode64(to_string(v)) do
      {:ok, value} ->
        config_base64(k, value)

      _ ->
        give_up()
    end
  end

  defp config_base64(key, value) do
    Enum.each(@config_start_apps, &Application.ensure_all_started/1)
    Enum.each(@config_apps, &ensure_app_started/1)

    case Config.update(%{key => value, originator: %System{}}) do
      {:ok, [{key, {:ok, _}}]} ->
        IO.puts("Successfully updated \"#{key}\" to \"#{value}\"")
        :init.stop()

      {:ok, [{key, {:error, :setting_not_found}}]} ->
        IO.puts("Error: \"#{key}\" is not a valid settings")
        :init.stop(1)

      _ ->
        give_up()
    end
  end
end
