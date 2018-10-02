defmodule EWallet.Web.Orchestrator do
  alias EWallet.Web.{Paginator, Preloader, SearchParser, SortParser}

  def to_query(query, attrs, overlay) do
    query
    |> Preloader.to_query(overlay.preload_assocs())
    |> SearchParser.to_query(attrs, overlay.search_fields, default_mapped_fields())
    |> SortParser.to_query(attrs, overlay.sort_fields, default_mapped_fields())
    |> Paginator.paginate_attrs(attrs)
  end

  defp default_mapped_fields do
    %{
      "created_at" => "inserted_at"
    }
  end
end
