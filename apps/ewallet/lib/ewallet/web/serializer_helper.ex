defmodule EWallet.Web.SerializerHelper do
  alias EWalletDB.Helpers.Preloader

  def preload_assocs(record, overlay) do
    Preloader.preload(record, overlay.preload_assocs)
  end

  def ensure_preloaded(record, overlay) do
    assocs = overlay.default_preload_assocs()
    unpreloaded = get_unpreloaded_assocs(record, assocs)

    unless unpreloaded == [] do
      raise "Missing preloaded fields: #{Enum.join(unpreloaded, ", ")}"
    end
  end

  def get_unpreloaded_assocs(record, associations) do
    Enum.reduce(associations, [], fn assoc, acc ->
      actual_assoc = Map.get(record, assoc)

      case is_loaded?(actual_assoc) do
        true -> acc
        false -> [actual_assoc.__field__ | acc]
      end
    end)
  end

  def is_loaded?(%Ecto.Association.NotLoaded{} = _), do: false
  def is_loaded?(_), do: true
end
