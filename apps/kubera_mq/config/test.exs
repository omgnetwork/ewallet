use Mix.Config

random_queue_name =
  30 |> :crypto.strong_rand_bytes |> Base.encode64 |> binary_part(0, 30)

System.put_env("MQ_LEDGER_QUEUE", "local_ledger_kubera_test")
System.put_env("MQ_EXCHANGE", System.get_env("MQ_EXCHANGE") ||
                              "#{random_queue_name}_transactions_exchange_test")

config :kubera_mq,
  mq_url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
  mq_exchange: System.get_env("MQ_EXCHANGE"),
  mq_publish_queues: [System.get_env("MQ_LEDGER_QUEUE")],
  mq_consume_queues: [System.get_env("MQ_LEDGER_QUEUE")]
