defmodule EWalletAPI.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [halt: 1]
  alias EWalletAPI.V1.JSON.{ErrorSerializer, ResponseSerializer}

  @errors %{
    invalid_auth_scheme: %{
      code: "client:invalid_auth_scheme",
      description: "The provided authentication scheme is not supported"
    },
    invalid_access_secret_key: %{
      code: "client:invalid_access_secret_key",
      description: "Invalid access and/or secret key"
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
    access_token_not_found: %{
      code: "user:access_token_not_found",
      description: "There is no user corresponding to the provided access_token"
    },
    access_token_expired: %{
      code: "user:access_token_expired",
      description: "The provided token is expired or has been invalidated"
    },
    provider_user_id_not_found: %{
      code: "user:provider_user_id_not_found",
      description: "There is no user corresponding to the provided provider_user_id"
    },
    balance_not_found: %{
      code: "user:balance_not_found",
      description: "There is no balance corresponding to the provided address"
    },
    transaction_request_not_found: %{
      code: "user:transaction_request_not_found",
      description: "There is no transaction request corresponding to the provided address"
    },
    user_balance_mismatch: %{
      code: "user:user_balance_mismatch",
      description: "The provided balance does not belong to the current user"
    },
    burn_balance_not_found: %{
      code: "user:burn_balance_not_found",
      description: "There is no burn balance corresponding to the provided name"
    },
    account_id_not_found: %{
      code: "user:account_id_not_found",
      description: "There is no account corresponding to the provided account_id"
    },
    minted_token_not_found: %{
      code: "user:minted_token_not_found",
      description: "There is no minted token matching the provided token_id."
    },
    from_address_not_found: %{
      code: "user:from_address_not_found",
      description: "No balance found for the provided from_address."
    },
    to_address_not_found: %{
      code: "user:to_address_not_found",
      description: "No balance found for the provided to_address."
    },
    no_idempotency_token_provided: %{
      code: "client:no_idempotency_token_provided",
      description: "The call you made requires the Idempotency-Token header to prevent duplication."
    }
  }

  # Used for mapping any Ecto.changeset validation
  # to make it more meaningful to send to the client.
  @validation_mapping %{
    unsafe_unique: "already_taken",
    all_or_none: "missing_dependent_params"
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

    respond(conn, code, description, messages)
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
        acc <> " " <> stringify_field(field) <> " " <> description <> "."
      end)
  end

  defp stringify_field(fields) when is_map(fields) do
    Enum.map_join(fields, ", ", fn({key, _}) -> stringify_field(key) end)
  end
  defp stringify_field(fields) when is_list(fields) do
    Enum.map(fields, &stringify_field/1)
  end
  defp stringify_field(field) when is_atom(field) do
    "`" <> to_string(field) <> "`"
  end
  defp stringify_field({key, _}) do
    "`" <> to_string(key) <> "`"
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
      |> ErrorSerializer.serialize(description, messages)
      |> ResponseSerializer.serialize(success: false)

    conn |> json(content) |> halt()
  end
end
