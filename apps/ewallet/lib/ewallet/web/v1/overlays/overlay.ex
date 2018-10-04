defmodule EWallet.Web.V1.Overlay do
  @callback preload_assocs() :: [Atom.t()]
  @callback default_preload_assocs() :: [Atom.t()]
  @callback search_fields() :: [Atom.t]
  @callback sort_fields() :: [Atom.t]
end
