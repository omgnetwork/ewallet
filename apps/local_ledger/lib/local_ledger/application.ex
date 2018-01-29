defmodule LocalLedger.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children =
      case System.get_env("CACHE_BALANCES_FREQUENCY") do
        nil -> []
        _ -> [supervisor(LocalLedger.Scheduler, [])]
      end

    opts = [strategy: :one_for_one, name: LocalLedger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
