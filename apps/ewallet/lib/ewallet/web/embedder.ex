defmodule EWallet.Web.Embedder do
  @moduledoc """
  This module allows embedding of related data into the response.
  """
  alias EWallet.Helper
  alias EWalletDB.Repo

  defmacro __using__(_opts) do
    quote do
      import EWallet.Web.Embedder, only: [embed: 2]
    end
  end

  defmacro embed(record, embeds) do
    quote do
      if is_nil(@embeddable) do
        raise(ArgumentError, message: "#{unquote(__MODULE__)} requires @embeddable to work")
      end

      if is_nil(@always_embed) do
        raise(ArgumentError, message: "#{unquote(__MODULE__)} requires @always_embed to work")
      end

      EWallet.Web.Embedder.embed(unquote(record), unquote(embeds), @embeddable, @always_embed)
    end
  end

  def embed(record, nil, embeddable, always_embed), do: embed(record, [], embeddable, always_embed)
  def embed(record, requested, embeddable, always_embed) do
    requested = Helper.to_existing_atoms(requested)

    # We could use `embeds -- (embeds -- embeddable)` but the complexity is O(N^3)
    # and we're dealing with user inputs here, so it's better to convert to `MapSet`
    # before operating on the lists.
    embeds     = MapSet.new(requested ++ always_embed)
    embeddable = MapSet.new(embeddable)
    filtered   = MapSet.intersection(embeds, embeddable)

    case MapSet.size(filtered) do
      n when n > 0 -> Repo.preload(record, MapSet.to_list(filtered))
      _            -> record
    end
  end
end
