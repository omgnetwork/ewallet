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
      alias EWalletDB.Repo

      setup do
        :ok = Sandbox.checkout(Repo)
      end
    end
  end
end
