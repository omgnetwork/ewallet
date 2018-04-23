defmodule EWallet.Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps(),
      aliases: aliases(),
      docs: docs()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end

  # Aliases for easier command executions
  def aliases do
    [
      init: [
        "ecto.create",
        "ecto.migrate",
        "seed"
      ],
      reset: [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate"
      ],
      seed: [
        "run apps/ewallet/priv/repo/seeder.exs"
      ]
    ]
  end

  def docs do
    [
      main: "introduction",
      extra_section: "Guides",
      extras: [
        {"README.md", [filename: "introduction", title: "Introduction"]},
        "docs/design/balances.md",
        "docs/design/components.md",
        "docs/design/entities.md",
        "docs/setup/clustering.md",
        "docs/setup/env.md",
        "docs/setup/integration.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "README.md"
        ],
        "Technical Design": [
          "docs/design/balances.md",
          "docs/design/components.md",
          "docs/design/entities.md"
        ],
        "Setting Up": [
          "docs/setup/clustering.md",
          "docs/setup/env.md",
          "docs/setup/integration.md"
        ]
      ],
      groups_for_modules: [
        eWallet: ~r/EWallet(\..+)*$/,
        "eWallet API": ~r/EWalletAPI(?!\.V\d+)(\..+)*$/,
        "eWallet API V1": ~r/EWalletAPI.V1(\..+)*$/,
        "eWallet DB": ~r/EWalletDB(\..+)*$/,
        "Local Ledger": ~r/LocalLedger(\..+)*$/,
        "Local Ledger DB": ~r/LocalLedgerDB(\..+)*$/,
        "Admin API": ~r/AdminAPI(?!\.V\d+)(\..+)*$/,
        "Admin API V1": ~r/AdminAPI.V1(\..+)*$/,
        "URL Dispatcher": ~r/UrlDispatcher(\..+)*$/
      ]
    ]
  end
end
