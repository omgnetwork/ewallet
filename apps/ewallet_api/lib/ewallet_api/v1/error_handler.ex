defmodule EWalletAPI.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [halt: 1]
  alias EWallet.Web.V1.ErrorHandler, as: EWalletErrorHandler
  alias EWallet.Web.V1.ResponseSerializer

  @errors %{
    invalid_access_secret_key: %{
      code: "client:invalid_access_secret_key",
      description: "Invalid access and/or secret key"
    },
    provider_user_id_not_found: %{
      code: "user:provider_user_id_not_found",
      description: "There is no user corresponding to the provided provider_user_id"
    },
    balance_not_found: %{
      code: "user:balance_not_found",
      description: "There is no balance corresponding to the provided address"
    },
    user_balance_mismatch: %{
      code: "user:user_balance_mismatch",
      description: "The provided balance does not belong to the current user"
    },
    account_balance_mismatch: %{
      code: "account:account_balance_mismatch",
      description: "The provided balance does not belong to the given account"
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
      code: "minted_token:minted_token_not_found",
      description: "There is no minted token matching the provided token_id."
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
    data = ResponseSerializer.serialize(data, success: false)
    conn |> json(data) |> halt()
  end
end
