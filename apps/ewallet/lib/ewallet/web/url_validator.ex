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

defmodule EWallet.Web.UrlValidator do
  @moduledoc """
  This module validates a url.
  """

  @doc """
  Checks that the given url is allowed as a redirect url in the application settings.
  """
  def allowed_redirect_url?(url) do
    base_url = Application.get_env(:ewallet, :base_url)
    prefixes = Application.get_env(:ewallet, :redirect_url_prefixes)
    allowed = [base_url | prefixes]

    Enum.any?(allowed, fn prefix -> allowed_redirect_url?(url, prefix) end)
  end

  @doc """
  Checks that the given url is allowed by the given prefix
  """
  def allowed_redirect_url?(url, prefix) do
    # Add trailing slashes to prevent urls such as 'https://example.comnotexample.com'
    # matching 'https://example.com'
    url = trailing_slashed(url)
    prefix = trailing_slashed(prefix)

    String.starts_with?(url, prefix)
  end

  defp trailing_slashed(string) do
    if String.ends_with?(string, "/"), do: string, else: string <> "/"
  end
end
