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

defmodule Utils.Helpers.InputAttribute do
  @moduledoc """
  Helper functions to deal with input attributes.
  """

  @doc """
  Get an input attribute by name.

  The name and the input key can be agnostically either an atom or string.
  """
  @spec get(map(), atom() | String.t()) :: any()
  def get(attrs, attr_name) when is_atom(attr_name) do
    Map.get(attrs, attr_name) || Map.get(attrs, to_string(attr_name))
  end

  def get(attrs, attr_name) when is_binary(attr_name) do
    Map.get(attrs, attr_name) || Map.get(attrs, String.to_existing_atom(attr_name))
  end
end
