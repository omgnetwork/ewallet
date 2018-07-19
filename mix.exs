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
        flags: ["-Wunmatched_returns", :error_handling, :underspecs],
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
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
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
        # Design
        "docs/design/components.md",
        "docs/design/conventions.md",
        "docs/design/databases.md",
        "docs/design/design.md",
        "docs/design/transactions_and_entries.md",
        "docs/design/wallets.md",
        # Guides
        "docs/guides/api_responsibilities.md",
        "docs/guides/api_specs.md",
        "docs/guides/entities.md",
        "docs/guides/ewallet_api_websockets.md",
        "docs/guides/faq.md",
        "docs/guides/guides.md",
        "docs/guides/transaction_request_flow.md",
        "docs/guides/usage.md",
        # Setup
        "docs/setup/adhoc/20180619-encryption-upgrade.md",
        "docs/setup/advanced/clustering.md",
        "docs/setup/advanced/env.md",
        "docs/setup/bare_metal.md",
        "docs/setup/docker.md",
        "docs/setup/vagrant.md",
        # Tests
        "docs/tests/e2e.md",
        "docs/tests/tests.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "README.md"
        ],
        "Setting Up": [
          "docs/setup/docker.md",
          "docs/setup/vagrant.md",
          "docs/setup/bare_metal.md"
        ],
        Guides: [
          "docs/guides/api_responsibilities.md",
          "docs/guides/usage.md",
          "docs/guides/entities.md",
          "docs/guides/transaction_request_flow.md",
          "docs/guides/ewallet_api_websockets.md",
          "docs/guides/api_specs.md",
          "docs/guides/faq.md"
        ],
        "Technical Design": [
          "docs/design/components.md",
          "docs/design/databases.md",
          "docs/design/wallets.md",
          "docs/design/transactions_and_entries.md",
          "docs/design/conventions.md"
        ],
        "Tests": [
          "docs/tests/tests.md",
          "docs/tests/e2e.md"
        ],
        "Advanced Setup": [
          "docs/setup/advanced/env.md",
          "docs/setup/advanced/clustering.md"
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
