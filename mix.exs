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
        flags: [:underspecs, :unknown, :unmatched_returns],
        plt_add_apps: [:iex, :mix],
        ignore_warnings: ".dialyzer_ignore.exs",
        flags: ~w(-Wunmatched_returns -Werror_handling -Wunderspecs)
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
      {:credo, "0.10.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:distillery, "~> 1.5", runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false},
      {:junit_formatter, "~> 2.2", only: :test}
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
        "docs/demo.md",
        "docs/faq.md",
        # Design
        "docs/design/components.md",
        "docs/design/conventions.md",
        "docs/design/databases.md",
        "docs/design/design.md",
        "docs/design/transactions_and_entries.md",
        "docs/design/wallets.md",
        # Guides
        "docs/guides/api_responsibilities.md",
        "docs/guides/entities.md",
        "docs/guides/ewallet_api_websockets.md",
        "docs/guides/guides.md",
        "docs/guides/transaction_request_flow.md",
        "docs/guides/usage.md",
        # Setup
        "docs/setup/advanced/api_specs.md",
        "docs/setup/advanced/clustering.md",
        "docs/setup/advanced/env.md",
        "docs/setup/advanced/settings.md",
        "docs/setup/upgrading/20180619-encryption-upgrade.md",
        "docs/setup/bare_metal.md",
        "docs/setup/docker.md",
        "docs/setup/vagrant.md",
        # Tests
        "docs/tests/tests.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "README.md",
          "docs/demo.md",
          "docs/faq.md"
        ],
        "Setting Up": [
          "docs/setup/docker.md",
          "docs/setup/vagrant.md",
          "docs/setup/bare_metal.md"
        ],
        Guides: [
          "docs/guides/usage.md",
          "docs/guides/api_responsibilities.md",
          "docs/guides/entities.md",
          "docs/guides/transaction_request_flow.md",
          "docs/guides/ewallet_api_websockets.md"
        ],
        "Technical Design": [
          "docs/design/components.md",
          "docs/design/databases.md",
          "docs/design/wallets.md",
          "docs/design/transactions_and_entries.md",
          "docs/design/conventions.md"
        ],
        Tests: [
          "docs/tests/tests.md"
        ],
        "Advanced Setup": [
          "docs/setup/advanced/env.md",
          "docs/setup/advanced/settings.md",
          "docs/setup/advanced/clustering.md",
          "docs/setup/advanced/api_specs.md"
        ]
      ],
      groups_for_modules: [
        "eWallet API": ~r/EWalletAPI(?!\.V\d+)(\..+)*$/,
        "eWallet API V1": ~r/EWalletAPI.V1(\..+)*$/,
        "Admin API": ~r/AdminAPI(?!\.V\d+)(\..+)*$/,
        "Admin API V1": ~r/AdminAPI.V1(\..+)*$/,
        eWallet: ~r/EWallet(\..+)*$/,
        "eWallet DB": ~r/EWalletDB(\..+)*$/,
        "Local Ledger": ~r/LocalLedger(\..+)*$/,
        "Local Ledger DB": ~r/LocalLedgerDB(\..+)*$/,
        "URL Dispatcher": ~r/UrlDispatcher(\..+)*$/
      ]
    ]
  end
end
