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

defmodule Utils.Types.Integer do
  @moduledoc """
  Custom Ecto type that converts DB's decimal value into integer.

  Ecto supports `:decimal` type out of the box (via `decimal` package). However,
  since this `:decimal` type requires its own functions to operate, e.g. `Decimal.add/2`,
  and we only work with whole numbers, we can safely convert to Elixir's primitive integer for easier operations.
  """
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(value) do
    {:ok, value}
  end

  def load(value) do
    {:ok, Decimal.to_integer(value)}
  end

  def load!(nil), do: 0

  def load!(value), do: Decimal.to_integer(value)

  def dump(value) do
    {:ok, value}
  end
end
