defmodule EthGethAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :eth_geth_adapter,
      version: "2.0.0-dev",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:utils, in_umbrella: true},
      {:keychain, in_umbrella: true},
      {:deferred_config, "~> 0.1.0"},
      {:ethereumex, "~> 0.5"},
      {:ex_abi, "0.2.1"},
      # Tests
      {:exexec, git: "https://github.com/pthomalla/exexec.git", branch: "add_streams", runtime: true, only: [:test]}
    ]
  end

  # This makes sure your factory and any other modules in test/support are
  # compiled when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
