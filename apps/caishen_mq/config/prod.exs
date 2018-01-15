use Mix.Config

ledger_queue = System.get_env("MQ_LEDGER_QUEUE") || "local_ledger"

config :caishen_mq,
  mq_ledger_queue: ledger_queue,
  rabbitmq_rpc: %{
    url: System.get_env("MQ_URL"),
    exchange: System.get_env("MQ_EXCHANGE"),
    publish_queues: [],
    consume_queues: [ledger_queue],
    publisher_name: :"caishen_mq.publisher",
    consumer_name: :"caishen_mq.consumer"
  }
