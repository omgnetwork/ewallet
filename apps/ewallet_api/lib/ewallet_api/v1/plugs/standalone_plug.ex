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

defmodule EWalletAPI.V1.StandalonePlug do
  @moduledoc """
  This plug enables the endpoint only if `enable_standalone` is true.
  """
  import EWalletAPI.V1.ErrorHandler

  def init(opts), do: opts

  def call(conn, _opts) do
    continue(conn, standalone?())
  end

  defp standalone? do
    Application.get_env(:ewallet_api, :enable_standalone) == true
  end

  defp continue(conn, true), do: conn

  defp continue(conn, false), do: handle_error(conn, :endpoint_not_found)
end
