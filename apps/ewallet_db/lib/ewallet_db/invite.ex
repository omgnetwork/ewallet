defmodule EWalletDB.Invite do
  @moduledoc """
  Ecto Schema representing invite.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletDB.{Repo, Invite, User}
  alias EWalletDB.Helpers.Crypto

  @primary_key {:uuid, UUID, autogenerate: true}
  @token_length 32
  @allowed_user_attrs [:email]

  schema "invite" do
    field(:token, :string)
    field(:success_url, :string)

    has_one(
      :user,
      User,
      foreign_key: :invite_uuid,
      references: :uuid
    )

    timestamps()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:token, :success_url])
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
        from(
          i in Invite,
          join: u in User,
          on: u.invite_uuid == i.uuid,
          where: field(u, ^user_attr) == ^value
        )

      Repo.one(query)
    else
      nil
    end
  end

  @doc """
  Fetches a specific invite by email and token.

  Returns `{:ok, invite}` when invite is found.
  Returns `{:error, :email_token_not_found}` otherwise.
  """
  @spec fetch(String.t(), String.t()) :: {:ok, %__MODULE__{}} | {:error, :email_token_not_found}
  def fetch(email, input_token) do
    case __MODULE__.get(email, input_token) do
      %__MODULE__{} = invite ->
        {:ok, invite}

      nil ->
        {:error, :email_token_not_found}
    end
  end

  @doc """
  Generates an invite for the given user.
  """
  def generate(user, opts \\ [preload: []]) do
    # Insert a new invite
    {:ok, invite} =
      insert(%{
        token: Crypto.generate_base64_key(@token_length),
        success_url: opts[:success_url]
      })

    # Assign the invite to the user
    changeset = change(user, invite_uuid: invite.uuid)
    {:ok, _user} = Repo.update(changeset)
    invite = Repo.preload(invite, opts[:preload])

    {:ok, invite}
  end

  defp insert(attrs) do
    %Invite{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Accepts an invitation without setting a new password.
  """
  @spec accept(%Invite{}) :: {:ok, struct()} | {:error, any()}
  def accept(invite) do
    invite = Repo.preload(invite, :user)

    case User.update_without_password(invite.user, %{invite_uuid: nil}) do
      {:ok, _user} ->
        Repo.delete(invite)

      error ->
        error
    end
  end

  @doc """
  Accepts an invitation and sets the given password to the user.
  """
  @spec accept(%Invite{}, String.t()) :: {:ok, struct()} | {:error, any()}
  def accept(invite, password) do
    invite = Repo.preload(invite, :user)

    case User.update(invite.user, %{invite_uuid: nil, password: password}) do
      {:ok, _user} ->
        Repo.delete(invite)

      error ->
        error
    end
  end
end
