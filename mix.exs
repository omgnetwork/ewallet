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
      docs: docs(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore"
      ]
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
      {:excoveralls, "~> 0.8", only: :test, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
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
        "omg.seed"
      ]
    ]
  end

  def docs do
    [
      assets: "assets/",
      main: "introduction",
      extra_section: "Guides",
      extras: [
        {"README.md", [filename: "introduction", title: "Introduction"]},
        "docs/design/components.md",
        "docs/design/databases.md",
        "docs/design/entities.md",
        "docs/design/transactions_and_entries.md",
        "docs/design/wallets.md",
        "docs/guides/transaction_request_flow.md",
        "docs/setup/clustering.md",
        "docs/setup/env.md",
        "docs/setup/integration.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "README.md"
        ],
        "Setting Up": [
          "docs/setup/clustering.md",
          "docs/setup/env.md",
          "docs/setup/integration.md"
        ],
        Guides: [
          "docs/guides/transaction_request_flow.md"
        ],
        "Technical Design": [
          "docs/design/entities.md",
          "docs/design/components.md",
          "docs/design/databases.md",
          "docs/design/wallets.md",
          "docs/design/transactions_and_entries.md"
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
