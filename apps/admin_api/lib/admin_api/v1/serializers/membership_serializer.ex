defmodule AdminAPI.V1.MembershipSerializer do
  @moduledoc """
  Serializes membership(s) into V1 response format.
  """
  alias AdminAPI.V1.UserSerializer
  alias EWalletDB.{Membership, User}

  def to_user_json(memberships) when is_list(memberships) do
    %{
      object: "list",
      data: Enum.map(memberships, &to_user_json/1)
    }
  end
  def to_user_json(membership) when is_map(membership) do
    user = Membership.get_user(membership)
    user
    |> UserSerializer.to_json()
    |> Map.put(:account_role, Membership.get_role_name(membership))
    |> Map.put(:status, User.get_status(user))
  end
end
