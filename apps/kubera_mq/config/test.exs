use Mix.Config

random_queue_name =
  30 |> :crypto.strong_rand_bytes |> Base.encode64 |> binary_part(0, 30)

ledger_queue = System.get_env("MQ_LEDGER_QUEUE") || "local_ledger_test"
ewallet_queue = System.get_env("MQ_EWALLET_QUEUE") || "ewallet_test"

config :kubera_mq,
  mq_ledger_queue: ledger_queue,
  mq_ewallet_queue: ewallet_queue,
  rabbitmq_rpc: %{
    url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
    exchange: System.get_env("MQ_EXCHANGE") || "#{random_queue_name}_transactions_exchange_test",
    publish_queues: [ledger_queue],
    consume_queues: [ledger_queue],
    publisher_name: :"kubera_mq.publisher",
    consumer_name: :"kubera_mq.consumer"
  }
