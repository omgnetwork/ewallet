defmodule Kubera.Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: [
        main: "introduction",
        extra_section: "Guides",
        extras: [
          {"README.md", [filename: "introduction", title: "Introduction"]},
          "docs/balances.md",
        ],
        groups_for_extras: [
          "Getting Started": ["README.md"],
          "Entities": ["docs/balances.md"],
        ],
        groups_for_modules: [
          "Kubera": ~r/Kubera(\..+)*$/,
          "Kubera API": ~r/KuberaAPI(?!\.V\d+)(\..+)*$/,
          "Kubera API V1": ~r/KuberaAPI.V1(\..+)*$/,
          "Kubera DB": ~r/KuberaDB(\..+)*$/,
          "Kubera MQ": ~r/KuberaMQ(\..+)*$/,
          "Kubera Admin": ~r/KuberaAdmin(?!\.V\d+)(\..+)*$/,
          "Kubera Admin V1": ~r/KuberaAdmin.V1(\..+)*$/,
        ],
      ],
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
    ]
  end

  # Aliases for easier command executions
  def aliases do
    [
      init: [
        "ecto.create",
        "ecto.migrate",
        "seed",
      ],
      reset: [
        "ecto.drop",
        "init",
        "seed",
      ],
      seed: [
        "run apps/kubera_db/priv/repo/seeds.exs"
      ]
    ]
  end
end
