use Mix.Config

System.put_env("MQ_LEDGER_QUEUE", System.get_env("MQ_LEDGER_QUEUE") || "local_ledger")
System.put_env("MQ_EWALLET_QUEUE", System.get_env("MQ_EWALLET_QUEUE") || "ewallet")

config :kubera_mq,
  mq_url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
  mq_exchange: System.get_env("MQ_EXCHANGE") || "kushen_exchange_dev",
  mq_publish_queues: [System.get_env("MQ_LEDGER_QUEUE")],
  mq_consume_queues: [System.get_env("MQ_EWALLET_QUEUE")]
