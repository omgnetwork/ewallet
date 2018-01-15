defmodule CaishenMQ.V1.Operators.Status do
  @moduledoc """
  Status operator (similar to a web controller) used to check if the application
  is alive and well.
  """
  alias CaishenMQ.ErrorHandler

  @doc """
  Used to ensure the app has finished booting.

  ## Payload

    {
      "operation": "status.check"
    }

  """
  def operate("check", _attrs) do
    %{success: true}
  end

  def operate(_, attrs) do
    ErrorHandler.invalid_operation(attrs)
  end
end
