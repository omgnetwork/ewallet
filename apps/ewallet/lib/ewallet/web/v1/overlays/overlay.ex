defmodule EWallet.Web.V1.Overlay do
  # The fields that can be preloaded.
  @callback preload_assocs() :: [Atom.t()]

  # The fields that should always be preloaded.
  # Note that these values *must be in the schema associations*.
  @callback default_preload_assocs() :: [Atom.t()]

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  @callback search_fields() :: [Atom.t()]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  @callback sort_fields() :: [Atom.t()]

  # The fields that are allowed to be filtered.
  @callback self_filter_fields() :: [Atom.t()]
  @callback filter_fields() :: [Atom.t()]
end
