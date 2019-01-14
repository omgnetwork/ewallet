defmodule EWallet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ewallet,
      version: "1.1.0-pre.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix] ++ Mix.compilers,
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
      mod: {EWallet.Application, []},
      extra_applications: [:sentry, :logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:bodyguard, "~> 2.2"},
      {:bypass, "~> 1.0.0", only: [:test]},
      {:csv, "~> 2.0.0"},
      {:decimal, "~> 1.0"},
      {:deferred_config, "~> 0.1.0"},
      {:ewallet_config, in_umbrella: true},
      {:ewallet_db, in_umbrella: true},
      {:local_ledger, in_umbrella: true},
      {:local_ledger_db, in_umbrella: true},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_html, "~> 2.11.0"},
      {:quantum, "~> 2.2.6"},
      {:sentry, "~> 6.4"},
      {:timex, "~> 3.0"},
    ]
  end
end
