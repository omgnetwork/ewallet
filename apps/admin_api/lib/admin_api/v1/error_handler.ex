defmodule AdminAPI.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [halt: 1]
  alias EWallet.Web.V1.ErrorHandler, as: EWalletErrorHandler

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
    unauthorized: %{
      code: "user:unauthorized",
      description: "The user is not allowed to perform the requested operation"
    },
    invalid_reset_token: %{
      code: "forget_password:token_not_found",
      description: "There are no password reset requests corresponding to the provided token"
    },
    user_email_not_found: %{
      code: "user:email_not_found",
      description: "There is no user corresponding to the provided email"
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
    invalid_email: %{
      code: "user:invalid_email",
      description: "The format of the provided email is invalid"
    },
    invite_not_found: %{
      code: "user:invite_not_found",
      description: "There is no invite corresponding to the provided email and token"
    },
    passwords_mismatch: %{
      code: "user:passwords_mismatch",
      description: "The provided passwords do not match"
    },
    key_not_found: %{
      code: "key:not_found",
      description: "The key could not be found"
    },
    api_key_not_found: %{
      code: "api_key:not_found",
      description: "The API key could not be found"
    },
    invalid_account_id: %{
      code: "client:invalid_account_id",
      description: "Invalid Account ID provided."
    }
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{required(atom()) => %{code: String.t, description: String.t}}
  def errors do
    Map.merge(EWalletErrorHandler.errors, @errors, fn _k, _shared, current ->
      current
    end)
  end

  @doc """
  Delegates calls to EWallet.Web.V1.ErrorHandler and pass the supported errors.
  """
  def handle_error(conn, code, attrs) do
    code
    |> EWalletErrorHandler.build_error(attrs, errors())
    |> respond(conn)
  end
  def handle_error(conn, code) do
    code
    |> EWalletErrorHandler.build_error(errors())
    |> respond(conn)
  end

  defp respond(data, conn) do
    conn |> json(data) |> halt()
  end
end
