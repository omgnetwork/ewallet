defmodule EWalletAPI.V1.AddressChannel do
  @moduledoc """
  Represents the address channel.
  """
  use Phoenix.Channel
  alias EWalletDB.User

  def join("address:" <> address, _params, %{assigns: %{auth: auth}} = socket) do
    join_as(auth, socket, address)
  end
  def join(_, _, _), do: {:error, %{code: :invalid_parameter}}

  defp join_as(%{authenticated: :provider}, socket, _) do
    {:ok, socket}
  end

  defp join_as(%{authenticated: :client, user: user}, socket, address) do
    user
    |> User.addresses()
    |> Enum.member?(address)
    |> case do
      true -> {:ok, socket}
      false -> {:error, %{code: :forbidden_channel}}
    end
  end
end
