use Mix.Config

# Required ENV Variables
#
# GCS_BUCKET
# GCS_CREDENTIALS

config :arc,
  storage: Arc.Storage.GCS,
  bucket: System.get_env("GCS_BUCKET")

config :goth,
  json: System.get_env("GCS_CREDENTIALS")
