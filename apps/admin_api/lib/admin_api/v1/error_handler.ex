# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [halt: 1]
  alias Ecto.Changeset
  alias EWallet.Web.V1.ErrorHandler, as: EWalletErrorHandler
  alias EWallet.Web.V1.ResponseSerializer

  @errors %{
    invalid_login_credentials: %{
      code: "user:invalid_login_credentials",
      description: "There is no user corresponding to the provided login credentials."
    },
    user_account_not_found: %{
      code: "user:account_not_found",
      description: "There is no account assigned to the provided user."
    },
    access_key_unauthorized: %{
      code: "access_key:unauthorized",
      description: "The current access key is not allowed to perform the requested operation."
    },
    invalid_email_update_token: %{
      code: "email_update:token_not_found",
      description: "There are no email update requests corresponding to the provided token."
    },
    auth_token_not_found: %{
      code: "auth_token:not_found",
      description: "There is no auth token corresponding to the provided token."
    },
    account_id_not_found: %{
      code: "account:id_not_found",
      description: "There is no account corresponding to the provided id."
    },
    transaction_id_not_found: %{
      code: "transaction:id_not_found",
      description: "There is no transaction corresponding to the provided id."
    },
    role_id_not_found: %{
      code: "role:id_not_found",
      description: "There is no role corresponding to the provided id."
    },
    role_name_not_found: %{
      code: "role:name_not_found",
      description: "There is no role corresponding to the provided name."
    },
    role_not_empty: %{
      code: "role:not_empty",
      description: "The role has one or more users associated."
    },
    membership_not_found: %{
      code: "membership:not_found",
      description: "The user is not assigned to the provided account."
    },
    invite_not_found: %{
      code: "user:invite_not_found",
      description: "There is no invite corresponding to the provided email and token."
    },
    passwords_mismatch: %{
      code: "user:passwords_mismatch",
      description: "The provided passwords do not match."
    },
    key_not_found: %{
      code: "key:not_found",
      description: "The key could not be found."
    },
    api_key_not_found: %{
      code: "api_key:not_found",
      description: "The API key could not be found."
    },
    invalid_account_id: %{
      code: "client:invalid_account_id",
      description: "Invalid Account ID provided."
    },
    category_id_not_found: %{
      code: "category:id_not_found",
      description: "There is no category corresponding to the provided id."
    },
    category_not_empty: %{
      code: "category:not_empty",
      description: "The category has one or more accounts associated."
    },
    exchange_pair_already_exists: %{
      code: "exchange:pair_already_exists",
      description: "The exchange pair for the given tokens already exists."
    },
    exchange_opposite_pair_not_found: %{
      code: "exchange:opposite_pair_not_found",
      description: "The opposite exchange pair for the given tokens could not be found."
    },
    export_no_records: %{
      code: "export:no_records",
      description: "The given export query did not return any records."
    },
    export_not_local: %{
      code: "export:not_local",
      description: "The given export is not stored locally."
    },
    file_not_found: %{
      code: "file:not_found",
      description: "The file could not be found on the server."
    }
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{required(atom()) => %{code: String.t(), description: String.t()}}
  def errors do
    Map.merge(EWalletErrorHandler.errors(), @errors, fn _k, _shared, current ->
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

  def handle_error(conn, %Changeset{} = changeset) do
    handle_error(conn, :invalid_parameter, changeset)
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
