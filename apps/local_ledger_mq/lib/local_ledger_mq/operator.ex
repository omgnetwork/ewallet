defmodule LocalLedgerMQ.Operator do
  @moduledoc """
  Dispatch the operation to the appropriate operator. Acts as a very simple
  router.
  """
  alias LocalLedgerMQ.ErrorHandler
  alias LocalLedgerMQ.V1.Operators.{Entry, Status, Balance}

  def operate(payload, correlation_id) do
    result =
      payload
      |> Poison.decode!()
      |> Map.put("correlation_id", correlation_id)
      |> operate()

    Poison.encode!(result)
  rescue
    Poison.SyntaxError ->
      ErrorHandler.invalid_payload |> Poison.encode!
    exception ->
      reraise exception, System.stacktrace
  end

  defp operate(%{"operation" => operation} = attrs) do
    operation |> String.split(".") |> dispatch(attrs)
  end

  defp operate(_attrs), do: ErrorHandler.no_operation()

  defp dispatch(["v1", operator, action], attrs) do
    case operator do
      "entry" -> Entry.operate(action, attrs)
      "status" -> Status.operate(action, attrs)
      "balance" -> Balance.operate(action, attrs)
      _ -> ErrorHandler.invalid_operation(attrs)
    end
  end

  defp dispatch([version, _operation, _action], _attrs) do
    ErrorHandler.invalid_version(version)
  end

  defp dispatch([_operation, _action], _attrs) do
    ErrorHandler.no_version()
  end
end
