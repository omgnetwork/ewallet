defmodule LocalLedger.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:local_ledger)

    children =
      case Application.get_env(:local_ledger, LocalLedger.Scheduler) do
        [jobs: [_jobs]] -> [supervisor(LocalLedger.Scheduler, [])]
        _ -> []
      end

    opts = [strategy: :one_for_one, name: LocalLedger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
