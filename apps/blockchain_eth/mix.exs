defmodule BlockchainEth.MixProject do
  use Mix.Project

  def project do
    [
      app: :blockchain_eth,
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
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:blockchain, in_umbrella: true},
      {:keychain, in_umbrella: true},
      {:exth_crypto, "~> 0.1.6"}
    ]
  end
end
