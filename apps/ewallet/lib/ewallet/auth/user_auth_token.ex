# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.UserAuthToken do
  @moduledoc """
  Handle user authentication with appropriate token between AuthToken and PreAuthToken.
  """

  alias EWalletDB.{User, AuthToken, PreAuthToken}

  def authenticate(nil, _, _), do: false

  def authenticate(_, nil, _), do: false

  def authenticate(%User{} = user, auth_token, owner_app) do
    cond do
      not User.enabled_2fa?(user) ->
        AuthToken.authenticate(user.id, auth_token, owner_app)

      PreAuthToken.get_by_token(auth_token, owner_app) == nil ->
        AuthToken.authenticate(user.id, auth_token, owner_app)

      true ->
        PreAuthToken.authenticate(user.id, auth_token, owner_app)
    end
  end

  def authenticate(user_id, auth_token, owner_app) do
    user = User.get(user_id)

    authenticate(user, auth_token, owner_app)
  end

  def generate(nil, _, _), do: {:error, :invalid_parameter}

  def generate(%User{} = user, owner_app, originator) do
    if User.enabled_2fa?(user) do
      PreAuthToken.generate(user, owner_app, originator)
    else
      AuthToken.generate(user, owner_app, originator)
    end
  end
end
