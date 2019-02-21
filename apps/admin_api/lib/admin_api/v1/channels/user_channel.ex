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

# credo:disable-for-this-file
defmodule AdminAPI.V1.UserChannel do
  @moduledoc """
  Represents the user channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.User
  alias EWallet.EndUserPolicy

  def join(
        "user:" <> user_id,
        _params,
        %{
          assigns: %{auth: auth}
        } = socket
      ) do
    with %User{} = user <- User.get(user_id) || User.get_by_provider_user_id(user_id),
         {:ok, _} <- EndUserPolicy.authorize(:listen, auth, user) do
      {:ok, socket}
    else
      _ ->
        {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
