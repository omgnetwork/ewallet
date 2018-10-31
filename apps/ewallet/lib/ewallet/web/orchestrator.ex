defmodule EWallet.Web.Orchestrator do
  @moduledoc """
    This module orchestrates the request attributes into search, filter, preload and sort queries,
    so that this set of features can be easily and consistently applied to controllers.

    This module should be used in every controller to deal with searching, filtering,
    preloading and sorting.
  """

  alias EWallet.Web.{MatchAllParser, MatchAnyParser, Paginator, Preloader, SearchParser, SortParser}

  def query(query, overlay, attrs \\ %{}) do
    query
    |> build_query(overlay, attrs)
    |> Paginator.paginate_attrs(attrs)
  end

  def build_query(query, overlay, attrs \\ %{}) do
    query
    |> preload_to_query(overlay, attrs)
    |> MatchAllParser.to_query(attrs, overlay.filter_fields())
    |> MatchAnyParser.to_query(attrs, overlay.filter_fields())
    |> SearchParser.to_query(attrs, overlay.search_fields, default_mapped_fields())
    |> SortParser.to_query(attrs, overlay.sort_fields, default_mapped_fields())
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
