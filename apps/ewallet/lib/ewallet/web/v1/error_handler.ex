defmodule EWallet.Web.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]
  alias Ecto.Changeset
  alias EWallet.Web.V1.ErrorSerializer
  alias EWalletDB.MintedToken

  @errors %{
    invalid_auth_scheme: %{
      code: "client:invalid_auth_scheme",
      description: "The provided authentication scheme is not supported"
    },
    invalid_version: %{
      code: "client:invalid_version",
      description: "Invalid API version",
      template: "Invalid API version Given: '{accept}'."
    },
    invalid_parameter: %{
      code: "client:invalid_parameter",
      description: "Invalid parameter provided"
    },
    invalid_api_key: %{
      code: "client:invalid_api_key",
      description: "The provided API key can't be found or is invalid"
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
    insufficient_funds: %{
      code: "transaction:insufficient_funds",
      template: "The specified balance ({address}) does not contain enough funds. " <>
                "Available: {current_amount} {friendly_id} - Attempted debit: " <>
                "{amount_to_debit} {friendly_id}"
    },
    transaction_request_not_found: %{
      code: "transaction_request:transaction_request_not_found",
      description: "There is no transaction request corresponding to the provided address"
    },
    same_address: %{
      code: "transaction:same_address",
      description: "Found identical addresses in senders and receivers: {address}."
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
    },
    expired_transaction_request: %{
      code: "transaction_request:expired",
      description: "The specified transaction request has expired."
    },
    max_consumptions_reached: %{
      code: "transaction_request:max_consumptions_reached",
      description:
        "The specified transaction request has reached the allowed amount of consumptions."
    },
    not_transaction_request_owner: %{
      code: "transaction_consumption:not_owner",
      description: "The given consumption can only be approved by the transaction request owner."
    },
    invalid_minted_token_provided: %{
      code: "transaction_consumption:invalid_minted_token",
      description: "The provided minted token does not match the transaction request minted token."
    },
    forbidden_channel: %{
      code: "websocket:forbidden_channel",
      description: "You don't have access to this channel."
    },
    channel_not_found: %{
      code: "websocket:channel_not_found",
      description: "The given channel does not exist."
    },
    websocket_connect_error: %{
      code: "websocket:connect_error",
      description: "Connection to websocket failed."
    }
  }

  # Used for mapping any Ecto.changeset validation
  # to make it more meaningful to send to the client.
  @validation_mapping %{
    unsafe_unique: "already_taken",
    all_or_none: "missing_dependent_params"
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{required(atom()) => %{code: String.t, description: String.t}}
  def errors, do: @errors

  # ---- WITH CHANGESET ----
  @doc """
  Handles response of invalid parameter error with error details provided.
  """
  @spec build_error(String.t, Ecto.Changeset.t, Map.t) :: Map.t
  def build_error(code, %Changeset{} = changeset, supported_errors) do
    run_if_valid_error(code, supported_errors, fn error ->
      build(
        code: error.code,
        desc: stringify_errors(changeset, error.description),
        msgs: error_fields(changeset)
      )
    end)
  end

  # ---- WITH CUSTOM CODE AND DESCRIPTION ----
  @doc """
  Handles response with custom error code and description.
  """
  @spec build_error(Atom.t, String.t, Map.t) :: Map.t
  def build_error(code, description, supported_errors)
  when is_binary(description)
  when is_atom(description)
  do
    run_if_valid_error(code, supported_errors, fn error ->
      build(code: error.code, desc: description)
    end)
  end

  # ---- WITH TEMPLATE DATA ----
  @doc """
  Handles response of insufficient_funds.
  """
  @spec build_error(Atom.t, Map.t, Map.t) :: Map.t
  def build_error(code, %{
    "address" => address,
    "current_amount" => current_amount,
    "amount_to_debit" => amount_to_debit,
    "friendly_id" => friendly_id
  }, supported_errors) do
    run_if_valid_error(code, supported_errors, fn error ->
      minted_token = MintedToken.get(friendly_id)

      data = %{
        "address" => address,
        "current_amount" => float_to_binary(current_amount / minted_token.subunit_to_unit),
        "amount_to_debit" => float_to_binary(amount_to_debit / minted_token.subunit_to_unit),
        "friendly_id" => minted_token.friendly_id
      }

      build(code: error.code, desc: build_template(data, error.template))
    end)
  end

  @doc """
  Handles response with template description to build.
  """
  @spec build_error(Atom.t, Map.t, Map.t) :: Map.t
  def build_error(code, data, supported_errors) when is_map(data) do
    run_if_valid_error(code, supported_errors, fn error ->
      build(code: error.code, desc: build_template(data, error.template))
    end)
  end

  # ---- WITH SUPPORTED CODE ----
  @doc """
  Handles response with default error code and description
  """
  @spec build_error(Atom.t, Map.t) :: Map.t
  def build_error(error_name, supported_errors) do
    run_if_valid_error(error_name, supported_errors, fn error ->
      build(code: error.code, desc: error.description)
    end)
  end

  defp run_if_valid_error(code, nil, func), do: run_if_valid_error(code, @errors, func)
  defp run_if_valid_error(code, supported_errors, func) when is_binary(code) do
    code
    |> String.to_existing_atom()
    |> run_if_valid_error(supported_errors, func)
  rescue
    ArgumentError -> internal_server_error(code)
  end
  defp run_if_valid_error(code, supported_errors, func) when is_atom(code) do
    case Map.fetch(supported_errors, code) do
      {:ok, error} -> func.(error)
      _            -> internal_server_error(code)
    end
  end

  defp internal_server_error(description) do
    build(code: :internal_server_error, desc: "#{description}")
  end

  defp build([code: code, desc: description]) do
    build([code: code, desc: description, msgs: nil])
  end
  defp build([code: code, desc: description, msgs: msgs]) do
    ErrorSerializer.serialize(code, description, msgs)
  end

  defp build_template(data, template) do
    Enum.reduce(data, template, fn({k, v}, desc) ->
      String.replace(desc, "{#{k}}", "#{v}")
    end)
  end

  defp stringify_errors(changeset, description) do
    Enum.reduce(changeset.errors, description, fn {field, {description, _values}}, acc ->
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

  defp float_to_binary(value) do
    :erlang.float_to_binary(value, [:compact, {:decimals, 1}])
  end

  defp error_fields(changeset) do
    traverse_errors(changeset, fn {_message, opts} ->
      validation = Keyword.get(opts, :validation)

      # Maps Ecto.changeset validation to be more meaningful
      # to send to the client.
      Map.get(@validation_mapping, validation, validation)
    end)
  end
end
