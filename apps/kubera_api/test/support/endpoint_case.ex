defmodule KuberaAPI.EndpointCase do
  @moduledoc """
  This module defines common behaviors shared between V1 endpoint tests.
  """

  def v1 do
    quote do
      @header_accept "application/vnd.omisego.v1+json" # The expected response version
      @expected_version "1" # The expected response version
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
