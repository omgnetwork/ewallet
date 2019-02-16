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

defmodule EWallet.Web.Preloader do
  @moduledoc """
  This module allows the preloading of specific associations for the given schema.
  It takes in a list of associations to preload as a list of atoms.
  """
  alias EWalletDB.Repo
  import Ecto.Query

  @doc """
  Preload the given list of associations.
  """
  @spec to_query(Ecto.Queryable.t(), [atom()]) :: {Ecto.Query.t()}
  def to_query(queryable, preload_fields) when is_list(preload_fields) do
    from(q in queryable, preload: ^preload_fields)
  end

  def to_query(queryable, _), do: queryable

  @doc """
  Preloads associations into the given record.
  """
  @spec preload_one(map, atom() | [atom()]) :: {:ok, Ecto.Schema.t()} | {:error, nil}
  def preload_one(record, preloads) when is_map(record) do
    case Repo.preload(record, List.wrap(preloads)) do
      nil -> {:error, nil}
      %{} = result -> {:ok, result}
    end
  end

  @doc """
  Preloads associations into the given records.
  """
  @spec preload_all(list(Ecto.Schema.t()), atom() | [atom()]) ::
          {:ok, [Ecto.Schema.t()]} | {:error, nil}
  def preload_all(record, preloads) do
    case Repo.preload(record, List.wrap(preloads)) do
      nil -> {:error, nil}
      result when is_list(result) -> {:ok, result}
    end
  end
end
