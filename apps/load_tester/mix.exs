defmodule LoadTester.MixProject do
  use Mix.Project

  def project do
    [
      app: :load_tester,
      version: "2.0.0-dev",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:appsignal, :logger],
      mod: {LoadTester.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:appsignal, "~> 1.9"},
      {:httpoison, "~> 1.0", override: true},
      {:chaperon, "~> 0.2.3"},
      {:deferred_config, "~> 0.1.0"},
    ]
  end
end
