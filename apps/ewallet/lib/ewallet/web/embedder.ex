defmodule EWallet.Web.Embedder do
  @moduledoc """
  This module allows embedding of related data into the response.
  """
  alias EWallet.Helper
  alias EWalletDB.Repo

  @callback embeddable() :: list(atom())
  @callback always_embed() :: list(atom())

  def embed(module, record, embeds) do
    embed(record, embeds, apply(module, :embeddable, []), apply(module, :always_embed, []))
  end

  defp embed(record, nil, embeddable, always_embed),
    do: embed(record, [], embeddable, always_embed)

  defp embed(record, requested, embeddable, always_embed) do
    requested = Helper.to_existing_atoms(requested) ++ always_embed
    allowed = embeddable -- embeddable -- requested

    Repo.preload(record, allowed)
  end
end
