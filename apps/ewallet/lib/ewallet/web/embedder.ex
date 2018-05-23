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
      alias EWallet.Web.Embedder

      if is_nil(@embeddable) do
        raise(ArgumentError, message: "#{unquote(__MODULE__)} requires @embeddable to work")
      end

      if is_nil(@always_embed) do
        raise(ArgumentError, message: "#{unquote(__MODULE__)} requires @always_embed to work")
      end

      Embedder.embed(unquote(record), unquote(embeds), @embeddable, @always_embed)
    end
  end

  @doc """
  Embed association data.
  """
  def embed(record, nil, embeddable, always_embed),
    do: embed(record, [], embeddable, always_embed)

  def embed(record, requested, embeddable, always_embed) do
    requested = Helper.to_existing_atoms(requested) ++ always_embed
    allowed = embeddable -- embeddable -- requested

    Repo.preload(record, allowed)
  end
end
