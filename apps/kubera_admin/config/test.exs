use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kubera_admin, KuberaAdmin.Endpoint,
  secret_key_base: "G1DLBdjjJSoSiQRa5Gf8YrWUx5yrX+JFmZx+UBk829W1+e0oJ9TYrW/GkIgrAdfm",
  http: [port: 5001],
  server: false
