defmodule Mix.Tasks.Omg.Seed do
  @moduledoc """
  Create initial seed data.

  ## Examples

  Simply run the following command:

      mix omg.seed
  """
  use Mix.Task
  alias EWallet.Seeder.CLI

  @shortdoc "Create initial seed data"
  @start_apps [:logger, :crypto, :ssl, :postgrex, :ecto, :cloak]
  @repo_apps [:ewallet_db, :local_ledger_db]

  def run(args) do
    spec = seed_spec(args)

    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Logger.configure(level: :info)

    Enum.each(@repo_apps, &ensure_started/1)
    CLI.run(spec)
  end

  #
  # Booting
  #

  defp ensure_started(app_name) do
    case Application.ensure_all_started(app_name) do
      {:ok, _} ->
        repos = Application.get_env(app_name, :ecto_repos, [])
        Enum.each(repos, & &1.start_link(pool_size: 1))

      _ ->
        nil
    end
  end

  #
  # Seed specs
  #

  defp seed_spec([]) do
    [{:ewallet_db, :seeds}]
  end

  defp seed_spec(["--sample" | t]) do
    seed_spec(t) ++ [{:ewallet_db, :seeds_sample}]
  end

  defp seed_spec([_ | t]) do
    seed_spec(t)
  end
end
