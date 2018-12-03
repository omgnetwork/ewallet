defmodule EWalletAPI.ViewCase do
  @moduledoc """
  This module defines common behaviors shared between V1 view tests.
  """

  def v1 do
    quote do
      use ExUnit.Case
      import EWalletDB.Factory
      import Phoenix.View
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Repo

      setup do
        :ok = Sandbox.checkout(Repo)
        :ok = Sandbox.checkout(ActivityLogger.Repo)
      end

      # The expected response version
      @expected_version "1"
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
