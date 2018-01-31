defmodule AdminAPI.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [halt: 1]
  alias Ecto.Changeset
  alias AdminAPI.V1.{ErrorSerializer, ResponseSerializer}

  @errors %{
    invalid_auth_scheme: %{
      code: "client:invalid_auth_scheme",
      description: "The provided authentication scheme is not supported"
    },
    invalid_api_key: %{
      code: "client:invalid_api_key",
      description: "The provided API key can't be found or is invalid"
    },
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
    unknown_error: %{
      code: "server:unknown_error",
      description: "An unknown error occured on the server"
    },
    access_token_not_found: %{
      code: "user:access_token_not_found",
      description: "There is no user corresponding to the provided access_token"
    },
    access_token_expired: %{
      code: "user:access_token_expired",
      description: "The provided token is expired or has been invalidated"
    },
    invalid_login_credentials: %{
      code: "user:invalid_login_credentials",
      description: "There is no user corresponding to the provided login credentials"
    },
    user_account_not_found: %{
      code: "user:account_not_found",
      description: "There is no account assigned to the provided user"
    },
    user_id_not_found: %{
      code: "user:id_not_found",
      description: "There is no user corresponding to the provided id"
    },
    account_id_not_found: %{
      code: "account:id_not_found",
      description: "There is no account corresponding to the provided id"
    },
    minted_token_id_not_found: %{
      code: "minted_token:id_not_found",
      description: "There is no minted token corresponding to the provided id"
    },
    transaction_id_not_found: %{
      code: "transaction:id_not_found",
      description: "There is no transaction corresponding to the provided id"
    },
    role_name_not_found: %{
      code: "role:name_not_found",
      description: "There is no role corresponding to the provided name"
    },
    membership_not_found: %{
      code: "membership:not_found",
      description: "The user is not assigned to the provided account"
    },
    invite_not_found: %{
      code: "user:invite_not_found",
      description: "There is no invite corresponding to the provided email and token"
    },
    passwords_mismatch: %{
      code: "user:passwords_mismatch",
      description: "The provided passwords do not match"
    }
  }

  # Used for mapping any Ecto.changeset validation
  # to make it more meaningful to send to the client.
  @validation_mapping %{
    unsafe_unique: "already_taken"
  }

  @doc """
  Handles response of invalid parameter error with error details provided.
  """
  def handle_error(conn, :invalid_parameter, %Changeset{} = changeset) do
    code =
      @errors.invalid_parameter.code
    description =
      stringify_errors(changeset, @errors.invalid_parameter.description <> ".")
    messages =
      error_fields(changeset)

    respond(conn, code, description, messages)
  end
  def handle_error(conn, :invalid_parameter, description) do
    respond(conn, @errors.invalid_parameter.code, description)
  end

  @doc """
  Handles response with custom error code and description.
  """
  def handle_error(conn, code, description) do
    respond(conn, code, description)
  end

  @doc """
  Handles response of invalid version error with accept header provided.
  """
  def handle_error(conn, :invalid_version) do
    code =
      @errors.invalid_version.code
    description =
      "Invalid API version. Given: \"" <> conn.assigns.accept <> "\"."

    respond(conn, code, description)
  end

  @doc """
  Handles response with default error code and description
  """
  def handle_error(conn, error_name) do
    case Map.fetch(@errors, error_name) do
      {:ok, error} ->
        respond(conn, error.code, error.description)
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

  defp respond(conn, code, description, messages \\ nil) do
    content =
      code
      |> ErrorSerializer.to_json(description, messages)
      |> ResponseSerializer.to_json(success: false)

    conn |> json(content) |> halt()
  end
end
