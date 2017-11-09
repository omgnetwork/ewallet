use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

# Reduce number of rounds so Bcrypt does not slow down tests.
config :bcrypt_elixir, :log_rounds, 4
