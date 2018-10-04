defmodule EWallet.Web.Orchestrator do
  alias EWallet.Web.{Paginator, Preloader, SearchParser, SortParser}

  def query(query, overlay, attrs \\ nil) do
    query
    |> preload_to_query(overlay, attrs)
    |> SearchParser.to_query(attrs, overlay.search_fields, default_mapped_fields())
    |> SortParser.to_query(attrs, overlay.sort_fields, default_mapped_fields())
    |> Paginator.paginate_attrs(attrs)
  end

  def one(record, overlay, attrs \\ nil)

  def one(record, _overlay, %{"preload" => preload}) when is_map(preload) do
    Preloader.preload_one(record, preload)
  end

  def one(record, _overlay, %{"preload" => preload}) when is_list(preload) do
    Preloader.preload_one(record, preload)
  end

  def one(record, overlay, _attrs) do
    Preloader.preload_one(record, overlay.default_preload_assocs())
  end

  def preload_to_query(query, _overlay, %{"preload" => preload}) when is_map(preload) do
    # Enum.filter()
    Preloader.to_query(query, preload)
  end

  def preload_to_query(query, _overlay, %{"preload" => preload}) when is_list(preload) do
    # assocs = get_string_assocs(overlay)
    #
    # Enum.filter(preload, fn assoc ->
    #   Enum.member?(assocs, assoc)
    # end)
    Preloader.to_query(query, preload)
  end

  def preload_to_query(query, overlay, _) do
    Preloader.to_query(query, overlay.default_preload_assocs())
  end

  # defp get_string_assocs(overlay) do
  #   Enum.map(overlay.default_preload_assocs(), fn assoc ->
  #     Atom.to_string(assoc)
  #   end)
  # end

  defp default_mapped_fields do
    %{
      "created_at" => "inserted_at"
    }
  end
end
