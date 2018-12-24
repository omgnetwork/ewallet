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

defmodule EWallet.EmailValidator do
  @moduledoc """
  This module validates an email string.
  """
  @email_regex ~r/^[^\@]+\@[^\@]+$/

  @doc """
  Checks whether the email address looks correct.
  """
  @spec valid?(String.t() | nil) :: boolean()
  def valid?(nil), do: false

  def valid?(email) do
    Regex.match?(@email_regex, email)
  end

  @doc """
  Checks whether the email address looks correct.
  Returns `{:ok, email}` if valid, returns `{:error, :invalid_email}` if invalid.
  """
  @spec validate(String.t() | nil) :: {:ok, String.t()} | {:error, :invalid_email}
  def validate(nil), do: {:error, :invalid_email}

  def validate(email) do
    if Regex.match?(@email_regex, email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end
end
