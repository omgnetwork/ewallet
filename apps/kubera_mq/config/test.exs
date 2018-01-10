use Mix.Config

random_queue_name =
  30 |> :crypto.strong_rand_bytes |> Base.encode64 |> binary_part(0, 30)

ledger_queue = System.get_env("MQ_LEDGER_QUEUE") || "local_ledger_test"
ewallet_queue = System.get_env("MQ_EWALLET_QUEUE") || "ewallet_test"

config :kubera_mq,
  mq_url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
  mq_exchange: System.get_env("MQ_EXCHANGE") || "#{random_queue_name}_transactions_exchange_test",
  mq_ledger_queue: ledger_queue,
  mq_ewallet_queue: ewallet_queue,
  mq_publish_queues: [ledger_queue],
  mq_consume_queues: [ledger_queue]
