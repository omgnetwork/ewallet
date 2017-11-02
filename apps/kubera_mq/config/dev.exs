use Mix.Config

config :kubera_mq,
  mq_url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
  mq_exchange: System.get_env("MQ_EXCHANGE") || "kushen_exchange_dev",
  mq_queue: System.get_env("MQ_QUEUE") || "kushen_queue_dev",
  mq_error_queue: System.get_env("MQ_ERROR_QUEUE") || "kushen_error_queue"
