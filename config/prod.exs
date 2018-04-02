use Mix.Config

level =
  case System.get_env("LOGGER_LEVEL") do
    "DEBUG" -> :debug
    "WARN"  -> :warn
    "ERROR" -> :error
    _       -> :info
  end

config :logger,
  level: level
