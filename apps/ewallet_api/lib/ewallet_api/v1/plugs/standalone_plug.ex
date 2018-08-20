defmodule EWalletAPI.V1.StandalonePlug do
  @moduledoc """
  This plug enables the endpoint only if `enable_standalone` is true.
  """
  import EWalletAPI.V1.ErrorHandler

  def init(opts), do: opts

  def call(conn, _opts) do
    if Application.get_env(:ewallet_api, :enable_standalone) do
      conn
    else
      handle_error(conn, :endpoint_not_found)
    end
  end
end
