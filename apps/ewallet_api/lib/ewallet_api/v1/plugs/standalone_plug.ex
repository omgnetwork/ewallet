defmodule EWalletAPI.V1.StandalonePlug do
  @moduledoc """
  This plug enables the endpoint only if `enable_standalone` is true.
  """
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Config

  def init(opts), do: opts

  def call(conn, _opts) do
    continue(conn, standalone?())
  end

  defp standalone?, do: Config.get_boolean(:ewallet_api, :enable_standalone)

  defp continue(conn, true), do: conn

  defp continue(conn, false), do: handle_error(conn, :endpoint_not_found)
end
