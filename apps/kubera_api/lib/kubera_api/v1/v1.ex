defmodule KuberaAPI.V1 do
  @moduledoc """
  The entrypoint for defining common behaviors in views for V1.
  """
  defmacro __using__(_opts) do
    quote do
      @version "1"
    end
  end
end
