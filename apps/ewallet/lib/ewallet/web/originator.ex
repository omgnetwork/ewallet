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

defmodule EWallet.Web.Originator do
  @moduledoc """
  Module to extract the originator from the conn.assigns.
  """
  alias EWalletDB.{Key, User}
  alias ActivityLogger.ActivityLog

  @spec extract(map()) :: %Key{}
  def extract(%{key: key}) do
    key
  end

  @spec extract(map()) :: %User{}
  def extract(%{admin_user: admin_user}) do
    admin_user
  end

  @spec extract(map()) :: %User{}
  def extract(%{end_user: user}) do
    user
  end

  @spec set_in_attrs(map(), struct(), String.t()) :: map()
  def set_in_attrs(attrs, originator, key \\ "originator") do
    Map.put(attrs, key, extract(originator))
  end

  @spec get_initial_originator(struct()) :: struct() | nil
  def get_initial_originator(record) do
    ActivityLog.get_initial_originator(record)
  end

  @spec get_initial_originator(struct(), module()) :: struct() | nil
  def get_initial_originator(record, repo) do
    ActivityLog.get_initial_originator(record, repo)
  end
end
