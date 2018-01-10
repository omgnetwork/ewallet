use Mix.Config

ledger_queue = System.get_env("MQ_LEDGER_QUEUE") || "local_ledger"
ewallet_queue = System.get_env("MQ_EWALLET_QUEUE") || "ewallet"

config :kubera_mq,
  mq_url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
  mq_exchange: System.get_env("MQ_EXCHANGE") || "kushen_exchange_dev",
  mq_ledger_queue: ledger_queue,
  mq_ewallet_queue: ewallet_queue,
  mq_publish_queues: [ledger_queue],
  mq_consume_queues: [ewallet_queue]
