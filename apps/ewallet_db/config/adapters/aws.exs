use Mix.Config

# Required ENV Variables
#
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_BUCKET
# AWS_REGION

bucket = System.get_env("AWS_BUCKET")
region = System.get_env("AWS_REGION")
aws_domain = "s3-" <> region <> ".amazonaws.com"

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: region,
  s3: [
    scheme: "https://",
    host: aws_domain,
    region: region
  ],
  debug_requests: true,
  recv_timeout: 60_000,
  hackney: [recv_timeout: 60_000, pool: false]

config :arc,
  storage: Arc.Storage.S3,
  bucket: bucket,
  asset_host: "https://#{aws_domain}/#{bucket}"
