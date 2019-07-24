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

defmodule EthGethAdapter.ErrorHandler do
  @moduledoc """
  Handles errors by mapping the error to its response code and description.
  """

  @errors %{
    geth_communication_error: %{
      code: "geth:communication_error",
      template:
        "Could not communicate with geth, make sure that there is a valid geth instance running at the specified url. Error: %{error_code}"
    },
    geth_error: %{
      code: "geth:error",
      template: "An error occured on the geth node: %{error_message}"
    }
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{required(atom()) => %{code: String.t(), description: String.t()}}
  def errors, do: @errors

  @doc """
  Handle different geth errors.
  """
  def handle_error(%{"message" => message}) do
    {:error, :geth_error, error_message: message}
  end

  def handle_error(code) when is_atom(code) do
    {:error, :geth_communication_error, error_code: code}
  end

  def handle_error(code, attrs) do
    {:error, code, attrs}
  end
end
