defmodule KuberaAPI.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]
  import Phoenix.Controller, only: [json: 2]
  alias KuberaAPI.V1.JSON.{ErrorSerializer, ResponseSerializer}

  @errors %{
    invalid_parameter: %{
      code: "client:invalid_parameter",
      description: "Invalid parameter provided"
    },
    invalid_version: %{
      code: "client:invalid_version",
      description: "Invalid API version"
    },
    endpoint_not_found: %{
      code: "client:endpoint_not_found",
      description: "Endpoint not found"
    },
    internal_server_error: %{
      code: "server:internal_server_error",
      description: "Something went wrong on the server"
    },
    provider_user_id_not_found: %{
      code: "user:provider_user_id_not_found",
      description: "There is no user corresponding to the provided provider_user_id"
    },
  }

  # Used for mapping any Ecto.changeset validation
  # to make it more meaningful to send to the client.
  @validation_mapping %{
    unsafe_unique: "already_taken"
  }

  @doc """
  Handles response of invalid parameter error with error details provided.
  """
  def handle_error(conn, :invalid_parameter, changeset) do
    code =
      @errors.invalid_parameter.code
    description =
      stringify_errors(changeset, @errors.invalid_parameter.description <> ".")
    messages =
      error_fields(changeset)

    render_error(conn, code, description, messages)
  end

  @doc """
  Handles response of invalid version error with accept header provided.
  """
  def handle_error(conn, :invalid_version) do
    render_error(
      conn,
      @errors.invalid_version.code, # Use default error code
      "Invalid API version. Given: \"" <> conn.assigns.accept <> "\"."
    )
  end

  @doc """
  Handles response with default error code and description
  """
  def handle_error(conn, error_name) do
    case Map.fetch(@errors, error_name) do
      {:ok, error} ->
        render_error(conn, error.code, error.description)
      _ ->
        handle_error(conn, :internal_server_error)
    end
  end

  defp stringify_errors(changeset, description) do
    Enum.reduce(changeset.errors, description,
      fn {field, {description, _values}}, acc ->
        acc <> " `" <> to_string(field) <> "` " <> description <> "."
      end)
  end

  defp error_fields(changeset) do
    traverse_errors(changeset, fn {_message, opts} ->
      validation = Keyword.get(opts, :validation)

      # Maps Ecto.changeset validation to be more meaningful
      # to send to the client.
      Map.get(@validation_mapping, validation, validation)
    end)
  end

  defp render_error(conn, code, description, messages \\ nil) do
    content =
      code
      |> ErrorSerializer.serialize(description, messages)
      |> ResponseSerializer.serialize(success: false)

    json(conn, content)
  end
end
