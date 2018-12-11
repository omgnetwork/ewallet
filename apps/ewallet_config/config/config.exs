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
    # Global Settings
    "base_url" => %{
      key: "base_url",
      value: "",
      type: "string",
      position: 100,
      description:
        "The domain name."
    },
    "redirect_url_prefixes" => %{
      key: "redirect_url_prefixes",
      value: [],
      type: "array",
      position: 101,
       description:
        "The whitelisted domains that eWallet is allowed to redirect to."
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
      type: "integer",
      position: 103,
      description: "The maximum number of records that can be returned for a list."
    },
    "min_password_length" => %{
      key: "min_password_length",
      value: 8,
      type: "integer",
      position: 104,
      description: "The minimum length for passwords."
    },
    "forget_password_request_lifetime" => %{
      key: "forget_password_request_lifetime",
      value: 10,
      type: "integer",
      position: 105,
      description: "The duration (in minutes) that a forget password request will be valid for."
    },

    # Email Settings
    "sender_email" => %{
      key: "sender_email",
      value: "admin@localhost",
      type: "string",
      position: 200,
      description: "The address from which system emails will be sent."
    },
    "email_adapter" => %{
      key: "email_adapter",
      value: "local",
      type: "string",
      position: 201,
      options: ["smtp", "local", "test"],
      description:
        "When set to local, a local email adapter will be used. Perfect for testing and development."
    },
    "smtp_host" => %{
      key: "smtp_host",
      value: nil,
      type: "string",
      position: 202,
      description: "The SMTP host to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_port" => %{
      key: "smtp_port",
      value: nil,
      type: "string",
      position: 203,
      description: "The SMTP port to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_username" => %{
      key: "smtp_username",
      value: nil,
      type: "string",
      position: 204,
      description: "The SMTP username to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_password" => %{
      key: "smtp_password",
      value: nil,
      type: "string",
      position: 205,
      description: "The SMTP password to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },

    # Balance Caching Settings
    "balance_caching_strategy" => %{
      key: "balance_caching_strategy",
      value: "since_beginning",
      type: "string",
      position: 300,
      options: ["since_beginning", "since_last_cached"],
      description:
        "The strategy to use for balance caching. It will either re-calculate from the beginning or from the last caching point."
    },

    # File Storage settings
    "file_storage_adapter" => %{
      key: "file_storage_adapter",
      value: "local",
      type: "string",
      position: 400,
      options: ["local", "gcs", "aws"],
      description: "The type of storage to use for images and files."
    },

    # File Storage: GCS Settings
    "gcs_bucket" => %{
      key: "gcs_bucket",
      value: nil,
      type: "string",
      position: 500,
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The name of the GCS bucket."
    },
    "gcs_credentials" => %{
      key: "gcs_credentials",
      value: nil,
      secret: true,
      type: "string",
      position: 501,
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The credentials of the Google Cloud account."
    },

    # File Storage: AWS Settings
    "aws_bucket" => %{
      key: "aws_bucket",
      value: nil,
      type: "string",
      position: 600,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The name of the AWS bucket."
    },
    "aws_region" => %{
      key: "aws_region",
      value: nil,
      type: "string",
      position: 601,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The AWS region where your bucket lives."
    },
    "aws_access_key_id" => %{
      key: "aws_access_key_id",
      value: nil,
      type: "string",
      position: 602,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS access key having access to the specified bucket."
    },
    "aws_secret_access_key" => %{
      key: "aws_secret_access_key",
      value: nil,
      secret: true,
      type: "string",
      position: 603,
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS secret having access to the specified bucket."
    }
  }

import_config "#{Mix.env()}.exs"
