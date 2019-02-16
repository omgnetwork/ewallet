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

defmodule EWallet.Web.V1.PaginatorSerializer do
  @moduledoc """
  Serializes a paginator into V1 response format.
  """
  alias EWallet.Web.Paginator

  @doc """
  Serializes a paginator into a list object in JSON format.
  If a mapper is provided, the paginator's data will be mapped before serialized.
  """
  def serialize(%Paginator{} = paginator, mapper) when is_function(mapper) do
    paginator
    |> Map.update!(:data, fn data -> Enum.map(data, mapper) end)
    |> serialize()
  end

  def serialize(%Paginator{} = paginator) do
    %{
      object: "list",
      data: paginator.data,
      pagination: paginator.pagination
    }
  end
end
