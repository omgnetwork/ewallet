use Mix.Config

config :ewallet_config,
  ecto_repos: [EWalletConfig.Repo],
  settings_mappings: %{
    "email_adapter" => %{
      "smtp" => Bamboo.SMTPAdapter,
      "local" => Bamboo.Bamboo.LocalAdapter,
      "test" => Bamboo.TestAdapter,
      "_" => Bamboo.Bamboo.LocalAdapter
    }
  },
  default_settings: %{
    # Global Settings
    "base_url" => %{key: "base_url", value: "", type: "string"},
    "redirect_url_prefixes" => %{key: "redirect_url_prefixes", value: [], type: "array"},
    "enable_standalone" => %{
      key: "enable_standalone",
      value: false,
      type: "boolean",
      description:
        "Enables the /user.signup endpoint in the client API, allowing users to sign up directly."
    },
    "max_per_page" => %{
      key: "max_per_page",
      value: 100,
      type: "integer",
      description: "The maximum number of records that can be returned for a list."
    },
    "min_password_length" => %{
      key: "min_password_length",
      value: 8,
      type: "integer",
      description: "The minimum length for passwords."
    },
    # Email Settings
    "sender_email" => %{
      key: "sender_email",
      value: "admin@localhost",
      type: "string",
      description: "The address from which system emails will be sent."
    },
    "email_adapter" => %{
      key: "email_adapter",
      value: false,
      type: "select",
      options: ["smtp", "local", "test"],
      description:
        "When set to local, a local email adapter will be used. Perfect for testing and development."
    },
    "smtp_host" => %{
      key: "smtp_host",
      value: nil,
      type: "string",
      description: "The SMTP host to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_port" => %{
      key: "smtp_port",
      value: nil,
      type: "string",
      description: "The SMTP port to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_username" => %{
      key: "smtp_username",
      value: nil,
      type: "string",
      description: "The SMTP username to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_password" => %{
      key: "smtp_password",
      value: nil,
      type: "string",
      description: "The SMTP password to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },

    # Balance Caching Settings
    "balance_caching_strategy" => %{
      key: "balance_caching_strategy",
      value: "since_beginning",
      type: "select",
      options: ["since_beginning", "since_last_cached"],
      description:
        "The strategy to use for balance caching. It will either re-calculate from the beginning or from the last caching point."
    },

    # File Storage settings
    "file_storage_adapter" => %{
      key: "file_storage_adapter",
      value: "local",
      type: "select",
      options: ["local", "gcs", "aws"],
      description: "The type of storage to use for images and files."
    },

    # File Storage: GCS Settings
    "gcs_bucket" => %{
      key: "gcs_bucket",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The name of the GCS bucket."
    },
    "gcs_credentials" => %{
      key: "gcs_credentials",
      value: nil,
      secret: true,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The credentials of the Google Cloud account."
    },

    # File Storage: AWS Settings
    "aws_bucket" => %{
      key: "aws_bucket",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The name of the AWS bucket."
    },
    "aws_region" => %{
      key: "aws_region",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The AWS region where your bucket lives."
    },
    "aws_access_key_id" => %{
      key: "aws_access_key_id",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS access key having access to the specified bucket."
    },
    "aws_secret_access_key" => %{
      key: "aws_secret_access_key",
      value: nil,
      secret: true,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS secret having access to the specified bucket."
    }
  }


import_config "#{Mix.env()}.exs"
