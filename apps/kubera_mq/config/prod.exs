use Mix.Config

config :kubera_mq,
  mq_url: System.get_env("MQ_URL"),
  mq_exchange: System.get_env("MQ_EXCHANGE"),
  mq_queue: System.get_env("MQ_QUEUE"),
  mq_error_queue: System.get_env("MQ_ERROR_QUEUE")
