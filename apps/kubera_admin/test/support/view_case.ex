defmodule KuberaAdmin.ViewCase do
  @moduledoc """
  This module defines common behaviors shared between V1 view tests.
  """

  def v1 do
    quote do
      use ExUnit.Case
      import KuberaDB.Factory
      import Phoenix.View

      @expected_version "1" # The expected response version
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
