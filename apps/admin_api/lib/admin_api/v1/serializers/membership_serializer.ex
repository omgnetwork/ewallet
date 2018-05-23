defmodule AdminAPI.V1.MembershipSerializer do
  @moduledoc """
  Serializes membership(s) into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.UserSerializer
  alias EWalletDB.User

  def serialize(memberships) when is_list(memberships) do
    %{
      object: "list",
      data: Enum.map(memberships, &serialize/1)
    }
  end

  def serialize(%NotLoaded{}), do: nil

  def serialize(membership) when is_map(membership) do
    membership.user
    |> UserSerializer.serialize()
    |> Map.put(:account_role, membership.role.name)
    |> Map.put(:status, User.get_status(membership.user))
  end

  def serialize(nil), do: nil
end
