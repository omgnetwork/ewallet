use Mix.Config

ledger_queue = System.get_env("MQ_LEDGER_QUEUE") || "local_ledger"
ewallet_queue = System.get_env("MQ_EWALLET_QUEUE") || "ewallet"

config :ewallet_mq,
  mq_ledger_queue: ledger_queue,
  mq_ewallet_queue: ewallet_queue,
  rabbitmq_rpc: %{
    url: System.get_env("MQ_URL"),
    exchange: System.get_env("MQ_EXCHANGE"),
    publish_queues: [ledger_queue],
    consume_queues: [ewallet_queue],
    publisher_name: :"ewallet_mq.publisher",
    consumer_name: :"ewallet_mq.consumer"
  }
