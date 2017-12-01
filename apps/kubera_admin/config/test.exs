use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kubera_admin, KuberaAdmin.Endpoint,
  http: [port: 5001],
  server: false
