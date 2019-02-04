defmodule LocalLedgerDB.Mixfile do
  use Mix.Project

  def project do
    [
      app: :local_ledger_db,
      version: "1.1.0-pre.3",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :postgrex, :ecto],
      mod: {LocalLedgerDB.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cloak, "~> 0.9.1"},
      {:deferred_config, "~> 0.1.0"},
      {:ecto, "~> 2.1.6"},
      {:ewallet_config, in_umbrella: true},
      {:ex_machina, "~> 2.2", only: :test},
      {:poison, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
    ]
  end

  # This makes sure your factory and any other modules in test/support are
  # compiled when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
