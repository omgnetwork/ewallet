defmodule EWallet.Web.SerializerCase do
  @moduledoc """
  This module defines common behaviors shared between V1 serializer tests.
  """

  def v1 do
    quote do
      use ExUnit.Case
      import EWalletDB.Factory
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Repo

      setup do
        :ok = Sandbox.checkout(EWalletDB.Repo)
        :ok = Sandbox.checkout(ActivityLogger.Repo)
      end
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
