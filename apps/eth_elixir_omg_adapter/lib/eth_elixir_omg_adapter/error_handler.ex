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

defmodule EthElixirOmgAdapter.ErrorHandler do
  @moduledoc """
  Handles errors by mapping the error to its response code and description.
  """

  @errors %{
    elixir_omg_connection_error: %{
      code: "elixir_omg:communication_error",
      description:
        "Could not communicate with the childchain, make sure that there is a valid childchain node running at the specified url."
    },
    elixir_omg_bad_request: %{
      code: "elixir_omg:bad_request",
      template: "An error occured on the childchain: %{error_code}"
    }
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{required(atom()) => %{code: String.t(), description: String.t()}}
  def errors, do: @errors
end
