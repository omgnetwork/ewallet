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

defmodule EWalletAPI.ViewCase do
  @moduledoc """
  This module defines common behaviors shared between V1 view tests.
  """

  def v1 do
    quote do
      use ExUnit.Case
      import EWalletDB.Factory
      import Phoenix.View
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Repo

      setup do
        :ok = Sandbox.checkout(Repo)
        :ok = Sandbox.checkout(ActivityLogger.Repo)
      end

      # The expected response version
      @expected_version "1"
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
