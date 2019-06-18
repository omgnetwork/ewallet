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

defmodule EWalletDB.Expirers.AuthExpirer do
  @moduledoc """
  Manages the expiration time of `AuthToken` or `PreAuthToken`.
  """

  alias EWalletDB.{AuthToken, PreAuthToken}

  @doc """
  Adds a specified amount of time (in second) to a NaiveDateTime.utc_now().

  If a specified amount of time is zero, then return nil.
  """
  @spec get_advanced_datetime(integer) :: NaiveDateTime.t() | nil
  def get_advanced_datetime(0), do: nil

  def get_advanced_datetime(second) when is_integer(second) do
    NaiveDateTime.add(NaiveDateTime.utc_now(), second, :second)
  end

  def get_advanced_datetime(_), do: nil

  @doc """
  Expire a given AuthToken or PreAuthToken if the datetime from `expired_at` field has been lapse.
  Otherwise, extend the `expired_at` by a given time in second.
  """
  @spec expire_or_refresh(AuthToken.t() | PreAuthToken.t(), integer) ::
          AuthToken.t() | PreAuthToken.t()
  def expire_or_refresh(nil, _), do: nil

  def expire_or_refresh(_, nil), do: nil

  def expire_or_refresh(token, configured_auth_token_lifetime) do
    if has_expired_at(token) or has_positive_lifetime(configured_auth_token_lifetime) do
      expire_or_refresh(
        :ok,
        token,
        token.expired_at || get_advanced_datetime(configured_auth_token_lifetime)
      )
    else
      token
    end
  end

  defp expire_or_refresh(:ok, token, expired_at) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.compare(expired_at)
    |> do_expire_or_refresh(token)
    |> handle_result()
  end

  defp has_positive_lifetime(configured_auth_token_lifetime) do
    configured_auth_token_lifetime != 0
  end

  defp has_expired_at(%{expired_at: expired_at}) do
    expired_at != nil
  end

  defp do_expire_or_refresh(:lt, token) do
    refresh(token)
  end

  defp do_expire_or_refresh(_, token) do
    expire(token)
  end

  defp expire(%AuthToken{} = token) do
    AuthToken.expire(token, token.user)
  end

  defp expire(%PreAuthToken{} = token) do
    PreAuthToken.expire(token, token.user)
  end

  defp refresh(%AuthToken{} = token) do
    AuthToken.refresh(token, token.user)
  end

  defp refresh(%PreAuthToken{} = token) do
    PreAuthToken.refresh(token, token.user)
  end

  defp handle_result({:ok, updated_token}) do
    updated_token
  end

  defp handle_result(error) do
    error
  end
end
