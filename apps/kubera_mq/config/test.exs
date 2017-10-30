use Mix.Config

random_queue_name =
  30 |> :crypto.strong_rand_bytes |> Base.encode64 |> binary_part(0, 30)

config :kubera_mq,
  mq_url: System.get_env("MQ_URL") || "amqp://guest:guest@localhost",
  mq_exchange: System.get_env("MQ_EXCHANGE") || "#{random_queue_name}_transactions_exchange_test",
  mq_queue: System.get_env("MQ_QUEUE") || random_queue_name,
  mq_error_queue: System.get_env("MQ_ERROR_QUEUE") ||
                    "#{random_queue_name}_error_queue"
