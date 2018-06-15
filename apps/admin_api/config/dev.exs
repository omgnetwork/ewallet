use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :admin_api, AdminAPI.Endpoint,
  secret_key_base: "p+A/M31eF7pNXK7q6pWKfBZbubUTF5x2NSX3pGwIOywHiOIN6PCgoZjTcAS81Vlz",
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :admin_api, AdminAPI.V1.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
