# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :load_tester,
  namespace: LoadTester,
  protocol: {:system, "LOADTEST_PROTOCOL", "https"},
  host: {:system, "LOADTEST_HOST", "localhost"},
  port: {:system, "LOADTEST_PORT", "4000"},
  total_requests: {:system, "LOADTEST_TOTAL_REQUESTS", "60"},
  duration: {:system, "LOADTEST_DURATION_SECONDS", "60"}
