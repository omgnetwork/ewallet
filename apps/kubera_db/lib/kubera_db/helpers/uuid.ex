defmodule KuberaDB.Helpers.UUID do
  @moduledoc """
  Helper module to check that a string is a valid UUID.
  """
  @regex ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/
  def regex, do: @regex

  def valid?(uuid) do
    String.match?(uuid, @regex)
  end
end
