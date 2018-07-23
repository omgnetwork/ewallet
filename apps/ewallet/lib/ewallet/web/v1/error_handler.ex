defmodule EWallet.Web.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]
  alias Ecto.Changeset
  alias EWallet.Web.V1.ErrorSerializer
  alias EWallet.AmountFormatter
  alias EWalletDB.Token

  @errors %{
    invalid_auth_scheme: %{
      code: "client:invalid_auth_scheme",
      description: "The provided authentication scheme is not supported"
    },
    invalid_version: %{
      code: "client:invalid_version",
      description: "Invalid API version",
      template: "Invalid API version Given: '%{accept}'."
    },
    unauthorized: %{
      code: "unauthorized",
      description: "You are not allowed to perform the requested operation"
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
    account_not_found: %{
      code: "account:not_found",
      description: "There is no user corresponding to the provided account id"
    },
    auth_token_not_found: %{
      code: "user:auth_token_not_found",
      description: "There is no account or user corresponding to the provided auth_token"
    },
    auth_token_expired: %{
      code: "user:auth_token_expired",
      description: "The provided token is expired or has been invalidated"
    },
    insufficient_funds: %{
      code: "transaction:insufficient_funds",
      template:
        "The specified wallet (%{address}) does not contain enough funds. " <>
          "Available: %{current_amount} %{token_id} - Attempted debit: " <>
          "%{amount_to_debit} %{token_id}"
    },
    inserted_transaction_could_not_be_loaded: %{
      code: "db:inserted_transaction_could_not_be_loaded",
      description:
        "We could not load the transaction after insertion. Please try submitting the same transaction again (with identical idempontecy token!)."
    },
    transaction_request_not_found: %{
      code: "transaction_request:transaction_request_not_found",
      description: "There is no transaction request corresponding to the provided ID."
    },
    transaction_consumption_not_found: %{
      code: "transaction_consumption:transaction_consumption_not_found",
      description: "There is no transaction consumption corresponding to the provided ID."
    },
    same_address: %{
      code: "transaction:same_address",
      description: "Found identical addresses in senders and receivers: %{address}."
    },
    from_address_not_found: %{
      code: "user:from_address_not_found",
      description: "No wallet found for the provided from_address."
    },
    user_from_address_mismatch: %{
      code: "user:from_address_mismatch",
      description: "The provided wallet address does not belong to the current user."
    },
    user_to_address_mismatch: %{
      code: "user:to_address_mismatch",
      description: "The provided wallet address does not belong to the current user."
    },
    account_from_address_mismatch: %{
      code: "account:from_address_mismatch",
      description: "The provided wallet address does not belong to the given account."
    },
    account_to_address_mismatch: %{
      code: "account:to_address_mismatch",
      description: "The provided wallet address does not belong to the given account."
    },
    to_address_not_found: %{
      code: "wallet:to_address_not_found",
      description: "No wallet found for the provided to_address."
    },
    wallet_address_not_found: %{
      code: "wallet:address_not_found",
      description: "There is no wallet corresponding to the provided address."
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
    max_consumptions_per_user_reached: %{
      code: "transaction_request:max_consumptions_per_user_reached",
      description:
        "The specified transaction request has reached the allowed amount of consumptions for the current user."
    },
    unauthorized_amount_override: %{
      code: "transaction_request:unauthorized_amount_override",
      description: "The amount for this transaction request cannot be overridden."
    },
    not_transaction_request_owner: %{
      code: "transaction_consumption:not_owner",
      description: "The given consumption can only be approved by the transaction request owner."
    },
    expired_transaction_consumption: %{
      code: "transaction_consumption:expired",
      description: "The specified transaction consumption has expired."
    },
    unfinalized_transaction_consumption: %{
      code: "transaction_consumption:unfinalized",
      description: "The specified transaction consumption has not been finalized yet."
    },
    invalid_token_provided: %{
      code: "transaction_consumption:invalid_token",
      description: "The provided token does not match the transaction request token."
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
    },
    websocket_format_error: %{
      code: "websocket:invalid_format",
      description: "The websocket payload could not be decoded."
    },
    token_not_found: %{
      code: "token:token_not_found",
      description: "There is no token matching the provided token_id."
    },
    from_token_not_found: %{
      code: "token:from_token_not_found",
      description: "There is no token matching the provided from_token_id."
    },
    to_token_not_found: %{
      code: "token:to_token_not_found",
      description: "There is no token matching the provided to_token_id."
    },
    user_wallet_mismatch: %{
      code: "user:user_wallet_mismatch",
      description: "The provided wallet does not belong to the current user"
    },
    account_wallet_mismatch: %{
      code: "account:account_wallet_mismatch",
      description: "The provided wallet does not belong to the given account"
    },
    invalid_access_secret_key: %{
      code: "client:invalid_access_secret_key",
      description: "Invalid access and/or secret key"
    },
    user_id_not_found: %{
      code: "user:id_not_found",
      description: "There is no user corresponding to the provided id"
    },
    provider_user_id_not_found: %{
      code: "user:provider_user_id_not_found",
      description: "There is no user corresponding to the provided provider_user_id"
    },
    wallet_not_found: %{
      code: "wallet:wallet_not_found",
      description: "There is no wallet corresponding to the provided address"
    },
    user_wallet_not_found: %{
      code: "user:wallet_not_found",
      description: "There is no user wallet corresponding to the provided address"
    },
    account_wallet_not_found: %{
      code: "account:wallet_not_found",
      description: "There is no account wallet corresponding to the provided address"
    },
    account_id_not_found: %{
      code: "user:account_id_not_found",
      description: "There is no account corresponding to the provided account_id"
    },
    exchange_pair_id_not_found: %{
      code: "exchange:pair_id_not_found",
      description: "There is no exchange pair corresponding to the provided id"
    },
    exchange_pair_not_found: %{
      code: "exchange:pair_not_found",
      description: "There is no exchange pair corresponding to the provided tokens"
    },
    exchange_invalid_rate: %{
      code: "exchange:invalid_rate",
      description: "The exchange is attempted with an invalid rate"
    },
    exchange_address_not_account: %{
      code: "exchange:exchange_wallet_not_owned_by_account",
      description: "The specified exchange_wallet is not owned by an account"
    },
    exchange_account_id_not_found: %{
      code: "exchange:account_id_not_found",
      description: "No account was found with the given exchange_account_id param"
    },
    exchange_client_not_allowed: %{
      code: "exchange:not_allowed",
      description: "Exchange consumptions cannot be made through the client API"
    },
    exchange_account_wallet_not_found: %{
      code: "exchange:account_wallet_not_found",
      description: "No wallet was found with the given exchange_wallet_address param"
    },
    amount_is_zero: %{
      code: "transaction:amount_is_zero",
      description: "Amount cannot be zero."
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
  @spec errors() :: %{
          required(atom()) => %{
            required(atom()) => String.t(),
            required(atom()) => String.t()
          }
        }
  def errors, do: @errors

  # ---- WITH CHANGESET ----
  @doc """
  Handles response of invalid parameter error with error details provided.
  """
  @spec build_error(String.t() | atom(), map() | Ecto.Changeset.t() | String.t(), map()) :: map()
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
  def build_error(code, description, supported_errors)
      when is_binary(description)
      when is_atom(description) do
    run_if_valid_error(code, supported_errors, fn error ->
      build(code: error.code, desc: description)
    end)
  end

  # ---- WITH TEMPLATE DATA ----
  @doc """
  Handles response of insufficient_funds.
  """
  def build_error(
        code,
        %{
          "address" => address,
          "current_amount" => current_amount,
          "amount_to_debit" => amount_to_debit,
          "token_id" => id
        },
        supported_errors
      ) do
    run_if_valid_error(code, supported_errors, fn error ->
      token = Token.get(id)

      data = %{
        "address" => address,
        "current_amount" => AmountFormatter.format(current_amount, token.subunit_to_unit),
        "amount_to_debit" => AmountFormatter.format(amount_to_debit, token.subunit_to_unit),
        "token_id" => token.id
      }

      build(code: error.code, desc: build_template(data, error.template))
    end)
  end

  @doc """
  Handles response with template description to build.
  """
  def build_error(code, data, supported_errors) when is_map(data) do
    run_if_valid_error(code, supported_errors, fn error ->
      build(code: error.code, desc: build_template(data, error.template))
    end)
  end

  # ---- WITH SUPPORTED CODE ----
  @doc """
  Handles response with default error code and description
  """
  @spec build_error(atom(), map() | nil) :: map()
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
      _ -> internal_server_error(code)
    end
  end

  defp internal_server_error(description) do
    build(code: :internal_server_error, desc: "#{description}")
  end

  defp build(code: code, desc: description) do
    build(code: code, desc: description, msgs: nil)
  end

  defp build(code: code, desc: description, msgs: msgs) do
    ErrorSerializer.serialize(code, description, msgs)
  end

  defp build_template(data, template) do
    Enum.reduce(data, template, fn {k, v}, desc ->
      String.replace(desc, "%{#{k}}", "#{v}")
    end)
  end

  defp stringify_errors(changeset, description) do
    Enum.reduce(changeset.errors, description, fn {field, {description, values}}, acc ->
      field = field |> stringify_field() |> replace_uuids()
      acc <> " " <> field <> " " <> build_template(values, description) <> "."
    end)
  end

  defp stringify_field(fields) when is_map(fields) do
    Enum.map_join(fields, ", ", fn {key, _} -> stringify_field(key) end)
  end

  defp stringify_field(fields) when is_list(fields) do
    Enum.map_join(fields, ", ", fn key -> stringify_field(key) end)
  end

  defp stringify_field(field) when is_atom(field) do
    "`" <> to_string(field) <> "`"
  end

  defp stringify_field(field) when is_binary(field) do
    field
  end

  defp stringify_field({key, _}) do
    "`" <> to_string(key) <> "`"
  end

  defp error_fields(changeset) do
    errors =
      traverse_errors(changeset, fn {message, opts} ->
        case opts do
          [] ->
            message

          _ ->
            validation = Keyword.get(opts, :validation)
            # Maps Ecto.changeset validation to be more meaningful
            # to send to the client.
            Map.get(@validation_mapping, validation, validation)
        end
      end)

    errors
    |> Enum.map(fn {key, value} ->
      {key |> replace_uuids() |> stringify_field(), value}
    end)
    |> Enum.into(%{})
  end

  defp replace_uuids(field) do
    field
    |> stringify_message_key()
    |> String.replace("_uuid", "_id")
  end

  defp stringify_message_key(fields) when is_map(fields) do
    Enum.map_join(fields, ", ", fn {key, _} -> stringify_message_key(key) end)
  end

  defp stringify_message_key(fields) when is_list(fields) do
    Enum.map_join(fields, ", ", fn key -> stringify_message_key(key) end)
  end

  defp stringify_message_key(field) when is_atom(field) do
    to_string(field)
  end

  defp stringify_message_key(field) when is_binary(field) do
    field
  end

  defp stringify_message_key({key, _}) do
    to_string(key)
  end
end
