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
    {EWallet.Mailer, [
      {:email_adapter, :adapter},
      {:smtp_host, :server},
      {:smtp_port, :port},
      {:smtp_username, :username},
      {:smtp_password, :password}
    ]}
  ]

import_config "#{Mix.env()}.exs"
