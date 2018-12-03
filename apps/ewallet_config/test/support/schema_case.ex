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
        Sandbox.checkout(Repo)
        Sandbox.checkout(ActivityLogger.Repo)
      end
    end
  end
end
