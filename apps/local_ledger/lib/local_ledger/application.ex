defmodule LocalLedger.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    opts = [strategy: :one_for_one, name: LocalLedger.Supervisor]

    case System.get_env("CACHE_BALANCES_FREQUENCY") do
      nil -> []
      _ -> [supervisor(LocalLedger.Scheduler, [])]
    end
    |> Supervisor.start_link(opts)
  end
end
