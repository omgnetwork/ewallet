# Copyright 2018 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.InviteController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.UserView
  alias EWallet.Web.{Originator, Preloader}
  alias EWalletDB.{Invite, User}

  @doc """
  Validates the user's invite token and activates the user.
  """
  @spec accept(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def accept(conn, %{
        "email" => email,
        "token" => token,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    with %Invite{} = invite <- Invite.get(email, token) || {:error, :invite_not_found},
         {:ok, invite} <- Preloader.preload_one(invite, :user),
         {:ok, _} <- Invite.accept(invite, password, password_confirmation),
         originator <- Originator.get_initial_originator(invite),
         {:ok, _} <- User.set_admin(invite.user, true, originator) do
      render(conn, UserView, :user, %{user: invite.user})
    else
      {:error, error_code} when is_atom(error_code) ->
        handle_error(conn, error_code)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def accept(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `email`, `token`, `password`, `password_confirmation` are required."
    )
  end
end
