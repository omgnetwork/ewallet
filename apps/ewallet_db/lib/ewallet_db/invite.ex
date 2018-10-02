defmodule EWalletDB.Invite do
  @moduledoc """
  Ecto Schema representing invite.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.{Multi, UUID}
  alias EWalletDB.{Audit, Helpers.Crypto, Invite, Repo, Types.VirtualStruct, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @token_length 32
  @allowed_user_attrs [:email]

  schema "invite" do
    field(:token, :string)
    field(:success_url, :string)
    field(:verified_at, :naive_datetime)
    field(:originator, VirtualStruct, virtual: true)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
  end

  defp changeset_insert(changeset, attrs) do
    changeset
    |> cast(attrs, [:user_uuid, :token, :success_url, :originator])
    |> validate_required([:user_uuid, :token, :originator])
  end

  defp changeset_accept(changeset, attrs) do
    changeset
    |> cast(attrs, [:verified_at, :originator])
    |> validate_required([:verified_at, :originator])
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
  def generate(user, opts \\ []) do
    originator = Audit.get_initial_originator(user)

    # Insert a new invite
    %Invite{}
    |> changeset_insert(%{
      user_uuid: user.uuid,
      token: Crypto.generate_base64_key(@token_length),
      success_url: opts[:success_url],
      originator: originator
    })
    |> Audit.insert_record_with_audit(
      # Assign the invite to the user
      Multi.run(Multi.new(), :user, fn %{record: record} ->
        {:ok, _user} =
          user
          |> change(%{invite_uuid: record.uuid})
          |> Repo.update()
      end)
    )
    |> case do
      {:ok, result} ->
        {:ok, Repo.preload(result.record, opts[:preload] || [])}

      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Accepts an invitation without setting a new password.
  """
  @spec accept(%Invite{}) :: {:ok, struct()} | {:error, any()}
  def accept(invite) do
    with invite <- Repo.preload(invite, :user),
         attrs <- %{invite_uuid: nil, originator: :self},
         {:ok, _user} <- User.update(invite.user, attrs),
         invite_attrs <- %{verified_at: NaiveDateTime.utc_now(), originator: invite.user},
         changeset <- changeset_accept(invite, invite_attrs),
         {:ok, result} <- Audit.update_record_with_audit(changeset) do
      {:ok, result.record}
    else
      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}

      error ->
        error
    end
  end

  @doc """
  Accepts an invitation and sets the given password to the user.
  """
  @spec accept(%Invite{}, String.t()) :: {:ok, struct()} | {:error, any()}
  def accept(invite, password) do
    with invite <- Repo.preload(invite, :user),
         password_attrs <- %{
           password: password,
           password_confirmation: password,
           originator: :self
         },
         {:ok, user} <- User.update_password(invite.user, password_attrs, ignore_current: true),
         user_attrs <- %{invite_uuid: nil, originator: :self},
         {:ok, _user} <- User.update(user, user_attrs),
         invite_attrs <- %{verified_at: NaiveDateTime.utc_now(), originator: invite.user},
         changeset <- changeset_accept(invite, invite_attrs),
         {:ok, result} <- Audit.update_record_with_audit(changeset) do
      {:ok, result.record}
    else
      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}

      error ->
        error
    end
  end
end
