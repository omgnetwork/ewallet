defmodule EWalletAPI.V1.StandalonePlug do
  @moduledoc """
  This plug enables the endpoint only if `enable_standalone` is true.
  """
  import EWalletAPI.V1.ErrorHandler
  alias EWalletDB.Setting

  def init(opts), do: opts

  def call(conn, _opts) do
    continue(conn, standalone?())
  end

  defp standalone? do
    case Setting.get("enable_standalone") do
      nil ->
        false

      setting ->
        setting.value == true
    end
  end

  defp continue(conn, true), do: conn

  defp continue(conn, false), do: handle_error(conn, :endpoint_not_found)
end
