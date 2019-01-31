defmodule EWalletDB.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ewallet_db,
      version: "1.1.0-pre.2",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
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
      mod: {EWalletDB.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:activity_logger, in_umbrella: true},
      {:arc, "~> 0.11.0"},
      {:arc_ecto, github: "omisego/arc_ecto"},
      {:bcrypt_elixir, "~> 1.0"},
      {:cloak, "~> 0.9.1"},
      {:deferred_config, "~> 0.1.0"},
      {:ecto, "~> 2.1.6"},
      {:ewallet_config, in_umbrella: true},
      {:ex_machina, "~> 2.2", only: :test},
      {:plug, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:timex, "~> 3.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
