# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ewallet,
  ecto_repos: [],
  settings: [
    :base_url,
    :sender_email,
    :max_per_page,
    :redirect_url_prefixes,
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
    "CORS_MAX_AGE" => "CORS_MAX_AGE",
    "CORS_ORIGIN" => "CORS_ORIGIN",
    "BALANCE_CACHING_STRATEGY" => "balance_caching_strategy",
    "REQUEST_MAX_PER_PAGE" => "max_per_page",
    "MIN_PASSWORD_LENGTH" => "min_password_length",
    "SENDER_EMAIL" => "sender_email",
    "EMAIL_ADAPTER" => "email_adapter",
    "SMTP_HOST" => "smtp_host",
    "SMTP_PORT" => "smtp_port",
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
