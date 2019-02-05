defmodule LocalLedger.Mixfile do
  use Mix.Project

  def project do
    [
      app: :local_ledger,
      version: "1.2.0-dev",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
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
      extra_applications: [:appsignal, :logger],
      mod: {LocalLedger.Application, []}
    ]
  end
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:appsignal, "~> 1.9"},
      {:deferred_config, "~> 0.1.0"},
      {:ewallet_config, in_umbrella: true},
      {:local_ledger_db, in_umbrella: true},
      {:quantum, ">= 2.3.4"},
      {:timex, "~> 3.0"},
    ]
  end
end
