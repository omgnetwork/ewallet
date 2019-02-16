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

defmodule EWallet.Web.MatchAnyParser do
  @moduledoc """
  Scopes an Ecto query with the "match_any" attribute.
  """
  alias EWallet.Web.{MatchParser, MatchAnyQuery}

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, attrs, whitelist, mappings \\ %{})

  def to_query(queryable, %{"match_any" => []}, _, _), do: queryable

  def to_query(queryable, %{"match_any" => inputs}, whitelist, mappings) do
    MatchParser.build_query(queryable, inputs, whitelist, false, MatchAnyQuery, mappings)
  end

  def to_query(queryable, _, _, _), do: queryable
end
