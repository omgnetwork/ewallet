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

defmodule EWallet.UserFetcher do
  @moduledoc """
  Handles the retrieval of users from the eWallet database.
  """
  alias EWalletDB.{User}

  @spec fetch(map()) :: {:ok, %User{}} | {:error, atom()}
  def fetch(%{"id" => id}) do
    with %User{} = user <- User.get(id) || :user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  def fetch(%{"user_id" => user_id}) do
    with %User{} = user <- User.get(user_id) || :user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  def fetch(%{"provider_user_id" => provider_user_id}) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  def fetch(_), do: {:error, :invalid_parameter}
end
