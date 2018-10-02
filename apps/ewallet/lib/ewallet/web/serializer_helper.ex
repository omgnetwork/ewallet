defmodule EWallet.Web.SerializerHelper do
  alias EWalletDB.Helpers.Preloader

  def ensure_preloaded(record, overlay, caller_schema) do
    assocs = overlay.preload_assocs()

    unpreloaded =
      record
      |> Preloader.get_unpreloaded_assocs(assocs)
      |> Enum.filter(fn unpreloaded_assoc ->
        assocs[unpreloaded_assoc] != caller_schema
      end)

    unless unpreloaded == [] do
      raise "Missing preloaded fields: #{Enum.join(unpreloaded, ", ")}"
    end
  end
end
