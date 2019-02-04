defmodule Utils.MixProject do
  use Mix.Project

  def project do
    [
      app: :utils,
      version: "1.1.0-pre.2",
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
      extra_applications: [:appsignal, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:appsignal, "~> 1.9"},
      {:ex_ulid, github: "omisego/ex_ulid"}
    ]
  end
end
