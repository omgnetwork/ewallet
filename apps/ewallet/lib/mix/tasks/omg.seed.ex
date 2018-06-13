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
  @e2e_disabled_warning """
  Test seeds can only be ran if the environment variable `E2E_ENABLED` is set to `true`
  """

  def run(args) do
    spec = seed_spec(args)
    assume_yes = assume_yes?(args)

    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Logger.configure(level: :info)

    Enum.each(@repo_apps, &ensure_started/1)
    CLI.run(spec, assume_yes)
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

  defp seed_spec(["--test" | _t]) do
    case System.get_env("E2E_ENABLED") do
      "true" ->
        [{:ewallet_db, :seeds_test}]
      _ ->
        IO.puts(@e2e_disabled_warning)
        []
    end
  end

  defp seed_spec([_ | t]) do
    seed_spec(t)
  end

  defp assume_yes?([]), do: false

  defp assume_yes?(["-y" | _t]), do: true

  defp assume_yes?(["--yes" | _t]), do: true

  defp assume_yes?(["--assume_yes" | _t]), do: true

  defp assume_yes?([_ | t]), do: assume_yes?(t)
end
