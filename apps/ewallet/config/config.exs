# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ewallet,
  ecto_repos: [],
  version: "1.1.0-pre.2",
  settings: [
    :base_url,
    :sender_email,
    :max_per_page,
    :redirect_url_prefixes,
    :aws_access_key_id,
    :aws_secret_access_key,
    :aws_region,
    :aws_bucket,
    :file_storage_adapter,
    :gcs_bucket,
    :gcs_credentials,
    {EWallet.Mailer,
     [
       {:email_adapter, :adapter},
       {:smtp_host, :server},
       {:smtp_port, :port},
       {:smtp_username, :username},
       {:smtp_password, :password}
     ]}
  ],
  env_migration_mapping: %{
    "BASE_URL" => "base_url",
    "REDIRECT_URL_PREFIXES" => "redirect_url_prefixes",
    "ENABLE_STANDALONE" => "enable_standalone",
    "BALANCE_CACHING_STRATEGY" => "balance_caching_strategy",
    "BALANCE_CACHING_RESET_FREQUENCY" => "balance_caching_reset_frequency",
    "REQUEST_MAX_PER_PAGE" => "max_per_page",
    "MIN_PASSWORD_LENGTH" => "min_password_length",
    "SENDER_EMAIL" => "sender_email",
    "EMAIL_ADAPTER" => "email_adapter",
    "SMTP_HOST" => "smtp_host",
    "SMTP_PORT" => "smtp_port",
    # `SMTP_USER` is not a valid setting name, but it was previously mentioned
    # in the documentation, so we also try to migrate that value here. This should
    # be safe enough as long as it stays above `SMTP_USERNAME` in this list, so that
    # `SMTP_USERNAME` always takes precedence over `SMTP_USER`.
    "SMTP_USER" => "smtp_username",
    "SMTP_USERNAME" => "smtp_username",
    "SMTP_PASSWORD" => "smtp_password",
    "FILE_STORAGE_ADAPTER" => "file_storage_adapter",
    "GCS_BUCKET" => "gcs_bucket",
    "GCS_CREDENTIALS" => "gcs_credentials",
    "AWS_BUCKET" => "aws_bucket",
    "AWS_REGION" => "aws_region",
    "AWS_ACCESS_KEY_ID" => "aws_access_key_id",
    "AWS_SECRET_ACCESS_KEY" => "aws_secret_access_key"
  }

import_config "#{Mix.env()}.exs"
