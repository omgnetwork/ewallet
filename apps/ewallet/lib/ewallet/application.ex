defmodule EWallet.Application do
  @moduledoc false
  use Application

  @precision 38

  def start(_type, _args) do
    import Supervisor.Spec

    set_decimal_context()
    # List all child processes to be supervised
    children = [
      worker(EWallet.Scheduler, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWallet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp set_decimal_context do
    Decimal.get_context()
    |> Map.put(:precision, @precision)
    |> Decimal.set_context()
  end
end
