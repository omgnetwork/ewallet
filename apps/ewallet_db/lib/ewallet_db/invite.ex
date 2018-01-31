defmodule EWalletDB.Invite do
  @moduledoc """
  Ecto Schema representing invite.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.{Multi, UUID}
  alias EWalletDB.{Repo, Account, Invite, Membership, Role, User}
  alias EWalletDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @token_length 32
  @allowed_user_attrs [:email]

  schema "invite" do
    field :token, :string
    has_one :user, User
    timestamps()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:token])
    |> validate_required([:token])
  end

  @doc """
  Retrieves a specific invite by its ID.
  """
  def get(id) do
    Repo.get(Invite, id)
  end

  @doc """
  Retrieves a specific invite by email and token.
  """
  def get(email, input_token) do
    case get(:user, :email, email) do
      %Invite{} = invite ->
        if Crypto.secure_compare(invite.token, input_token), do: invite, else: nil
      _ ->
        nil
    end
  end

  @doc """
  Retrieves a specific invite by the given user's attribute.

  Only user attributes defined in `@allowed_user_attrs` can be used.
  """
  def get(:user, user_attr, value) do
    if Enum.member?(@allowed_user_attrs, user_attr) do
      query =
        from i in Invite,
          join: u in User, on: u.invite_id == i.id,
          where: field(u, ^user_attr) == ^value

      Repo.one(query)
    else
      nil
    end
  end

  @doc """
  Generates an invite for the given user.
  """
  def generate(user, opts \\ []) do
    # Insert a new invite
    {:ok, invite} = insert(%{token: Crypto.generate_key(@token_length)})

    # Assign the invite to the user
    changeset     = change(user, invite_id: invite.id)
    {:ok, _user}  = Repo.update(changeset)
    invite        = Repo.preload(invite, opts[:preload])

    {:ok, invite}
  end

  defp insert(attrs) do
    %Invite{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
