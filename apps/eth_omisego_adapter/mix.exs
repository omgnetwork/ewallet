defmodule EthOmiseGOAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :eth_omisego_adapter,
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
      mod: {EthOmiseGOAdapter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:utils, in_umbrella: true},
      {:keychain, in_umbrella: true},
      {:ewallet_config, in_umbrella: true},
      {:deferred_config, "~> 0.1.0"},
      {:ex_rlp, "~> 0.5.3"},
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.4.0"},
      {:ex_plasma, git: "https://github.com/omgnetwork/ex_plasma.git", ref: "0336be01bea7b4aeb5b7fbd75edcbe4ad0d1c69f"},
      {:plug_cowboy, "~> 1.0", only: [:dev]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
