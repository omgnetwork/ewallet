defmodule AdminAPI.V1.MembershipSerializer do
  @moduledoc """
  Serializes membership(s) into V1 response format.
  """
  alias AdminAPI.V1.UserSerializer
  alias EWalletDB.User

  def to_user_json(memberships) when is_list(memberships) do
    %{
      object: "list",
      data: Enum.map(memberships, &to_user_json/1)
    }
  end
  def to_user_json(membership) when is_map(membership) do
    membership.user
    |> UserSerializer.serialize()
    |> Map.put(:account_role, membership.role.name)
    |> Map.put(:status, User.get_status(membership.user))
  end
end
