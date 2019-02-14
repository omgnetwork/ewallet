defmodule LoadTester.MixProject do
  use Mix.Project

  def project do
    [
      app: :load_tester,
      version: "1.2.0-dev",
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
      {:chaperon, github: "omisego/chaperon"},
      {:deferred_config, "~> 0.1.0"},
    ]
  end
end
