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

defmodule EWallet.Web.Orchestrator do
  @moduledoc """
    This module orchestrates the request attributes into search, filter, preload and sort queries,
    so that this set of features can be easily and consistently applied to controllers.

    This module should be used in every controller to deal with searching, filtering,
    preloading and sorting.
  """
  alias Ecto.Query

  alias EWallet.Web.{
    MatchAllParser,
    MatchAnyParser,
    Paginator,
    Preloader,
    SearchParser,
    SortParser
  }

  alias EWalletDB.Repo

  def query(query, overlay, attrs \\ %{}, repo \\ Repo) do
    with %Ecto.Query{} = query <- build_query(query, overlay, attrs),
         paginated <-
           Paginator.paginate_attrs(
             query,
             attrs,
             overlay.pagination_fields(),
             repo,
             default_mapped_fields()
           ) do
      paginated
    else
      {:error, :not_allowed, field} ->
        {:error, :query_field_not_allowed, field_name: field}

      {:error, :missing_filter_param, params} ->
        {:error, :missing_filter_param, filter_params: params}

      {:error, _, _} = error ->
        error
    end
  end

  def build_query(query, overlay, attrs \\ %{}) do
    with %Query{} = query <- preload_to_query(query, overlay, attrs),
         %Query{} = query <-
           MatchAllParser.to_query(query, attrs, overlay.filter_fields(), default_mapped_fields()),
         %Query{} = query <-
           MatchAnyParser.to_query(query, attrs, overlay.filter_fields(), default_mapped_fields()),
         %Query{} = query <-
           SearchParser.to_query(query, attrs, overlay.search_fields, default_mapped_fields()),
         %Query{} = query <-
           SortParser.to_query(query, attrs, overlay.sort_fields, default_mapped_fields()) do
      query
    else
      error -> error
    end
  end

  def all(records, overlay, attrs \\ %{})

  def all(records, _overlay, %{"preload" => preload}) when is_map(preload) do
    Preloader.preload_all(records, preload)
  end

  def all(records, _overlay, %{"preload" => preload}) when is_list(preload) do
    Preloader.preload_all(records, preload)
  end

  def all(records, overlay, _attrs) do
    Preloader.preload_all(records, overlay.default_preload_assocs())
  end

  def one(record, overlay, attrs \\ %{})

  def one(record, _overlay, %{"preload" => preload}) when is_map(preload) do
    Preloader.preload_one(record, preload)
  end

  def one(record, _overlay, %{"preload" => preload}) when is_list(preload) do
    Preloader.preload_one(record, preload)
  end

  def one(record, overlay, _attrs) do
    Preloader.preload_one(record, overlay.default_preload_assocs())
  end

  def preload_to_query(record, overlay, attrs \\ %{})

  def preload_to_query(query, _overlay, %{"preload" => preload}) when is_map(preload) do
    Preloader.to_query(query, preload)
  end

  def preload_to_query(query, _overlay, %{"preload" => preload}) when is_list(preload) do
    Preloader.to_query(query, preload)
  end

  def preload_to_query(query, overlay, _) do
    Preloader.to_query(query, overlay.default_preload_assocs())
  end

  defp default_mapped_fields do
    %{
      "created_at" => "inserted_at"
    }
  end
end
