use Mix.Config

ledger_queue = System.get_env("MQ_LEDGER_QUEUE") || "local_ledger"

config :local_ledger_mq,
  mq_ledger_queue: ledger_queue,
  rabbitmq_rpc: %{
    url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
    exchange: System.get_env("MQ_EXCHANGE") || "kushen_exchange_dev",
    publish_queues: [],
    consume_queues: [ledger_queue],
    publisher_name: :"local_ledger_mq.publisher",
    consumer_name: :"local_ledger_mq.consumer"
  }
