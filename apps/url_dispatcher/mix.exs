defmodule UrlDispatcher.Mixfile do
  use Mix.Project

  def project do
    [
      app: :url_dispatcher,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug, :admin_api, :admin_panel, :ewallet_api],
      mod: {UrlDispatcher.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.2"},
      {:cowboy, "~> 1.0"},
      {:admin_api, in_umbrella: true},
      {:admin_panel, in_umbrella: true},
      {:ewallet_api, in_umbrella: true}
    ]
  end
end
