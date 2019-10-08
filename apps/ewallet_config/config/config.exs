use Mix.Config

config :ewallet_config,
  ecto_repos: [EWalletConfig.Repo],
  settings_mappings: %{
    "email_adapter" => %{
      "smtp" => Bamboo.SMTPAdapter,
      "local" => Bamboo.LocalAdapter,
      "test" => Bamboo.TestAdapter,
      "_" => Bamboo.LocalAdapter
    }
  },
  default_settings: %{
    #
    # Global Settings
    #

    "master_account" => %{
      key: "master_account",
      value: "",
      type: "string",
      position: 000,
      description:
        "The master account of this eWallet, which will be used as the default account when needed."
    },
    "primary_hot_wallet" => %{
      key: "primary_hot_wallet",
      value: "",
      type: "string",
      position: 001,
      description: "The primary hot wallet for this eWallet."
    },

    #
    # Web settings
    #

    "base_url" => %{
      key: "base_url",
      value: "",
      type: "string",
      position: 100,
      description: "The URL where the base of the eWallet is accessible from."
    },
    "redirect_url_prefixes" => %{
      key: "redirect_url_prefixes",
      value: [],
      type: "array",
      position: 101,
      description:
        "The URL prefixes where the eWallet are allowed to redirect to (for password resets, etc.)"
    },
    "enable_standalone" => %{
      key: "enable_standalone",
      value: false,
      type: "boolean",
      position: 102,
      description:
        "Enables the /user.signup endpoint in the client API, allowing users to sign up directly."
    },
    "max_per_page" => %{
      key: "max_per_page",
      value: 100,
      type: "unsigned_integer",
      position: 103,
      description: "The maximum number of records that can be returned for a list."
    },
    "min_password_length" => %{
      key: "min_password_length",
      value: 8,
      type: "unsigned_integer",
      position: 104,
      description: "The minimum length for passwords."
    },
    "forget_password_request_lifetime" => %{
      key: "forget_password_request_lifetime",
      value: 10,
      type: "unsigned_integer",
      position: 105,
      description: "The duration (in minutes) that a forget password request will be valid for."
    },
    "auth_token_lifetime" => %{
      key: "auth_token_lifetime",
      value: 0,
      type: "unsigned_integer",
      position: 106,
      description:
        "The duration (in seconds) that an auth token will be valid for. Set to 0 to never expire an auth token."
    },
    "pre_auth_token_lifetime" => %{
      key: "pre_auth_token_lifetime",
      value: 0,
      type: "unsigned_integer",
      position: 107,
      description:
        "The duration (in seconds) that a pre auth token will be valid for. Set to 0 to never expire a pre auth token."
    },
    "number_of_backup_codes" => %{
      key: "number_of_backup_codes",
      value: 10,
      type: "unsigned_integer",
      position: 108,
      description: "The number of backup codes for the two-factor authentication."
    },
    "two_fa_issuer" => %{
      key: "two_fa_issuer",
      value: "OmiseGO",
      type: "string",
      position: 109,
      description:
        "The issuer for the two-factor authentication, which will be displayed the OTP app."
    },

    #
    # Blockchain settings
    #

    "blockchain_chain_id" => %{
      key: "blockchain_chain_id",
      value: 0,
      type: "unsigned_integer",
      position: 201,
      description:
        "The chain ID of the blockchain network used. Such as 1 for Ethereum mainnet, " <>
          "3 for Ropsten testnet, 4 for Rinkeby testnet, etc."
    },
    "blockchain_json_rpc_url" => %{
      key: "blockchain_json_rpc_url",
      value: "http://localhost:8545",
      type: "string",
      position: 202,
      description: "The JSON-RPC url for interacting with the blockchain client."
    },
    "blockchain_confirmations_threshold" => %{
      key: "blockchain_confirmations_threshold",
      value: 10,
      type: "unsigned_integer",
      position: 203,
      description:
        "The number of confirmations to wait for before confirming a blockchain transaction."
    },
    "blockchain_state_save_interval" => %{
      key: "blockchain_state_save_interval",
      value: 5,
      type: "unsigned_integer",
      position: 204,
      description: "The number of blocks to wait before saving the block number to database."
    },
    "blockchain_sync_interval" => %{
      key: "blockchain_sync_interval",
      value: 1_000,
      type: "unsigned_integer",
      position: 205,
      description:
        "The interval (in milliseconds) between each blockchain polling for new information." <>
          " This value is used at application startup to catch up with the blockchain's latest" <>
          " state. After it has caught up, it switches to the polling interval instead."
    },
    "blockchain_poll_interval" => %{
      key: "blockchain_poll_interval",
      value: 5_000,
      type: "unsigned_integer",
      position: 206,
      description:
        "The interval (in milliseconds) between each blockchain polling for new information." <>
          " This value is used after the application has caught up with the blockchain's" <>
          " latest state."
    },
    "blockchain_transaction_poll_interval" => %{
      key: "blockchain_transaction_poll_interval",
      value: 5_000,
      type: "unsigned_integer",
      position: 207,
      description:
        "The interval (in milliseconds) between each blockchain polling for new information" <>
          " about a specific transaction."
    },
    "blockchain_deposit_pooling_interval" => %{
      key: "blockchain_deposit_pooling_interval",
      value: 24 * 60 * 60 * 1_000,
      type: "unsigned_integer",
      position: 208,
      description:
        "The interval (in milliseconds) to check and pool funds from blockchain deposit wallets."
    },

    #
    # Email Settings
    #

    "sender_email" => %{
      key: "sender_email",
      value: "admin@localhost",
      type: "string",
      position: 300,
      description: "The address from which system emails will be sent."
    },
    "email_adapter" => %{
      key: "email_adapter",
      value: "local",
      type: "string",
      position: 301,
      options: ["smtp", "local", "test"],
      description:
        "When set to local, a local email adapter will be used. Perfect for testing and development."
    },
    "smtp_host" => %{
      key: "smtp_host",
      value: nil,
      type: "string",
      position: 302,
      description: "The SMTP host to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_port" => %{
      key: "smtp_port",
      value: nil,
      type: "string",
      position: 303,
      description: "The SMTP port to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_username" => %{
      key: "smtp_username",
      value: nil,
      type: "string",
      position: 304,
      description: "The SMTP username to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_password" => %{
      key: "smtp_password",
      value: nil,
      type: "string",
      position: 305,
      description: "The SMTP password to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },

    #
    # Balance Caching Settings
    #

    "balance_caching_strategy" => %{
      key: "balance_caching_strategy",
      value: "since_beginning",
      type: "string",
      position: 400,
      options: ["since_beginning", "since_last_cached"],
      description:
        "The strategy to use for balance caching. It will either re-calculate from the beginning or from the last caching point."
    },
    "balance_caching_frequency" => %{
      key: "balance_caching_frequency",
      # Daily at 2am: 0 2 * * *
      # Every Friday at 5am: 0 5 * * 5
      value: "0 2 * * *",
      type: "string",
      position: 401,
      description:
        "The frequency to compute the balance cache. Expecting a 5-field crontab format. For example, 0 2 * * * for a daily run at 2AM."
    },
    "balance_caching_reset_frequency" => %{
      key: "balance_caching_reset_frequency",
      value: 10,
      type: "unsigned_integer",
      position: 402,
      parent: "balance_caching_strategy",
      parent_value: "since_last_cached",
      description:
        "A counter is incremented everytime balances are cached, once reaching the given reset frequency," <>
          " the balances are re-calculated from the beginning and the counter is reset." <>
          " Set to 0 to always cache balances based on the previous cached value"
    },

    #
    # File storage settings
    #

    "file_storage_adapter" => %{
      key: "file_storage_adapter",
      value: "local",
      type: "string",
      position: 500,
      options: ["local", "gcs", "aws"],
      description: "The type of storage to use for images and files."
    },

    # File Storage: GCS Settings
    "gcs_bucket" => %{
      key: "gcs_bucket",
      value: nil,
      type: "string",
      position: 510,
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The name of the GCS bucket."
    },
    "gcs_credentials" => %{
      key: "gcs_credentials",
      value: nil,
      secret: true,
      type: "string",
      position: 511,
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The credentials of the Google Cloud account."
    },

    # File Storage: AWS Settings
    "aws_bucket" => %{
      key: "aws_bucket",
      value: nil,
      type: "string",
      position: 520,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The name of the AWS bucket."
    },
    "aws_region" => %{
      key: "aws_region",
      value: nil,
      type: "string",
      position: 521,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The AWS region where your bucket lives."
    },
    "aws_access_key_id" => %{
      key: "aws_access_key_id",
      value: nil,
      type: "string",
      position: 522,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS access key having access to the specified bucket."
    },
    "aws_secret_access_key" => %{
      key: "aws_secret_access_key",
      value: nil,
      secret: true,
      type: "string",
      position: 523,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS secret having access to the specified bucket."
    }
  }

config :ewallet_config, EWalletConfig.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: DB.SharedConnectionPool,
  pool_size: {:system, "EWALLET_POOL_SIZE", 15, {String, :to_integer}},
  shared_pool_id: :ewallet,
  migration_timestamps: [type: :naive_datetime_usec]

import_config "#{Mix.env()}.exs"
