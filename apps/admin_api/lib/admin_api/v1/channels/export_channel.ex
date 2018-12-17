# credo:disable-for-this-file
defmodule AdminAPI.V1.ExportChannel do
  @moduledoc """
  Represents the export channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.Export

  def join("export:" <> export_id, _params, %{assigns: %{auth: auth}} = socket) do
    join_as(export_id, auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(export_id, %{authenticated: true}, socket) do
    export_id |> Account.get() |> respond(socket)
  end

  defp join_as(_, _, _), do: {:error, :forbidden_channel}

  defp respond(nil, _socket), do: {:error, :channel_not_found}
  defp respond(_export, socket), do: {:ok, socket}
end
