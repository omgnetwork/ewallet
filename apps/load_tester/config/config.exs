# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :load_tester,
  namespace: LoadTester,
  loadtest_host: {:system, "LOADTEST_HOST", "localhost"},
  loadtest_port: {:system, "LOADTEST_PORT", "4000"}
