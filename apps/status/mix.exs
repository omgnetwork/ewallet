defmodule Status.Mixfile do
  use Mix.Project

  def project do
    [
      app: :status,
      version: "1.2.0-dev",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {Status, []},
      extra_applications: [:appsignal, :logger, :sasl, :os_mon]
    ]
  end

  defp deps, do: [{:utils, in_umbrella: true}]
  defp aliases, do: []
end
