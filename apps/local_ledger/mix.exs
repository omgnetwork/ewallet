defmodule LocalLedger.Mixfile do
  use Mix.Project

  def project do
    [
      app: :local_ledger,
      version: "0.1.0-beta",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
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
      extra_applications: [:logger],
      mod: {LocalLedger.Application, []}
    ]
  end
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:local_ledger_db, in_umbrella: true},
      {:quantum, ">= 2.2.1"},
      {:timex, "~> 3.0"}
    ]
  end
end
