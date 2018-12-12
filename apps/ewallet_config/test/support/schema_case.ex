defmodule EWalletConfig.SchemaCase do
  @moduledoc """
  This module defines common behaviors shared for EWalletConfig schema tests.
  """
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWalletConfig.SchemaCase
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletConfig.Repo

      setup do
        # Restarts `EWalletConfig.Config` so it does not hang on to a DB connection for too long.
        Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
        Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

        Sandbox.checkout(Repo)
      end
    end
  end
end
