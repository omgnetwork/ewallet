defmodule EWalletDB.ValidatorCase do
  @moduledoc """
  This module defines common behaviors shared for EWalletDB's validator tests.
  """

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Ecto.Changeset
      import EWalletDB.Factory
      alias Ecto.Adapters.SQL.Sandbox

      setup do
        :ok = Sandbox.checkout(EWalletDB.Repo)
        :ok = Sandbox.checkout(EWalletConfig.Repo)

        :ok
      end
    end
  end
end
