defmodule AdminAPI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :admin_api,
      version: "1.1.0-pre.2",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
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
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AdminAPI.Application, []},
      extra_applications: [:sentry, :logger, :runtime_tools, :appsignal]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:appsignal, "~> 1.9"},
      {:bodyguard, "~> 2.2"},
      {:bypass, "~> 1.0.0", only: [:test]},
      {:cors_plug, "~> 1.5"},
      {:csv, "~> 2.0.0"},
      {:deferred_config, "~> 0.1.0"},
      {:ewallet, in_umbrella: true},
      {:ewallet_config, in_umbrella: true},
      {:ewallet_db, in_umbrella: true},
      {:phoenix, "~> 1.3.0"},
      {:plug_cowboy, "~> 1.0"},
      {:sentry, "~> 7.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
