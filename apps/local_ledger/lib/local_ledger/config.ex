defmodule LocalLedger.Config do
  @moduledoc """
  Provides a configuration function that are called during application startup.
  """

  def read_scheduler_config do
    case System.get_env("BALANCE_CACHING_FREQUENCY") do
      nil ->
        []

      frequency ->
        [
          cache_all_wallets: [
            schedule: frequency,
            task: {LocalLedger.Balance, :cache_all, []},
            run_strategy: {Quantum.RunStrategy.Random, :cluster}
          ]
        ]
    end
  end
end
