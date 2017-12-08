defmodule KuberaAPI.SerializerCase do
  @moduledoc """
  This module defines common behaviors shared between V1 serializer tests.
  """

  def v1 do
    quote do
      use ExUnit.Case
      import KuberaDB.Factory
      alias KuberaDB.Repo
      alias Ecto.Adapters.SQL.Sandbox

      setup do
        :ok = Sandbox.checkout(Repo)
      end
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
