defmodule CaishenMQ.ErrorHandler do
  @moduledoc """
  Error operator handling operators and operations not found.
  """
  alias CaishenMQ.V1.Serializers.{Error, Response}

  @errors %{
    internal_server_error:   "server:internal_server_error",
    no_operation:            "client:no_operation",
    no_version:              "client:no_version",
    invalid_operation:       "client:invalid_operation",
    invalid_version:         "client:invalid_version",
    invalid_payload:         "client:invalid_payload",
    invalid_uuid:            "client:invalid_uuid",
    not_found:               "client:not_found",
    invalid_data:            "client:invalid_data",
    insufficient_funds:      "client:insufficient_funds"
  }

  def handle(:internal_server_error = code, exception) do
    # credo:disable-for-next-line
    respond(@errors[code], IO.inspect(exception))
  end

  def internal_server_error(exception) do
    # credo:disable-for-next-line
    respond(@errors[:internal_server_error], IO.inspect(exception))
  end

  def no_operation do
    respond(@errors[:no_operation], "No operation given.")
  end

  def no_version do
    respond(@errors[:no_version], "No version given.")
  end

  def invalid_operation(%{"operation" => operation}) do
    respond(@errors[:invalid_operation],
            "The operation '#{operation}' was not found.")
  end

  def invalid_version(version) do
    respond(@errors[:invalid_version],
            "The version '#{version}' was not found.")
  end

  def invalid_payload do
    respond(@errors[:invalid_payload], "Could not decode payload as JSON.")
  end

  def invalid_uuid(id) do
    respond(@errors[:invalid_uuid],
            "The given id ('#{id}') is not a valid UUID.")
  end

  def invalid_data(data) do
    respond(@errors[:invalid_data],
            "The submitted data were not valid.",
            data)
  end

  def invalid_data do
    respond(@errors[:invalid_data],
            "The submitted data were not valid.")
  end

  def not_found(id) do
    respond(@errors[:not_found],
            "No record was found with the id '#{id}'.")
  end

  def insufficient_funds(e) do
    respond(@errors[:insufficient_funds], e.message)
  end

  defp respond(error, message, data) do
    error
    |> Error.serialize(message, data)
    |> Response.serialize(success: false)
  end

  defp respond(error, message) do
    error
    |> Error.serialize(message)
    |> Response.serialize(success: false)
  end
end
