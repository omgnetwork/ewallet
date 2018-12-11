defmodule EWalletDB.ForgetPasswordRequest do
  @moduledoc """
  Ecto Schema representing a password reset request.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletConfig.Helpers.Crypto
  alias EWalletDB.{Repo, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @token_length 32
  @default_lifetime_minutes 10

  schema "forget_password_request" do
    field(:token, :string)
    field(:enabled, :boolean)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    field(:used_at, :naive_datetime)
    field(:expires_at, :naive_datetime)

    timestamps()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:token, :user_uuid, :expires_at])
    |> validate_required([:token, :user_uuid, :expires_at])
    |> assoc_constraint(:user)
  end

  defp expire_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:enabled])
    |> validate_required([:enabled])
  end

  defp expire_as_used_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:enabled, :used_at])
    |> validate_required([:enabled, :used_at])
  end

  @doc """
  Retrieves all active requests.
  """
  @spec all_active() :: [%__MODULE__{}]
  def all_active do
    __MODULE__
    |> where([f], f.enabled == true)
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  @doc """
  Retrieves a specific invite by its token.
  """
  @spec get(%User{} | nil, String.t() | nil) :: %__MODULE__{} | nil
  def get(nil, _), do: nil
  def get(_, nil), do: nil

  def get(user, token) do
    requests =
      __MODULE__
      |> where([f], f.user_uuid == ^user.uuid)
      |> where([f], f.enabled == true)
      |> Repo.all()
      |> Repo.preload(:user)

    Enum.find(requests, fn r -> check_token(r, token) end)
  end

  defp check_token(nil, _token), do: nil

  defp check_token(request, token) do
    if Crypto.secure_compare(request.token, token), do: request, else: nil
  end

  @doc """
  Expires the given request.
  """
  @spec expire(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def expire(request) do
    request
    |> expire_changeset(%{enabled: false})
    |> Repo.update()
  end

  @doc """
  Expires the given request and set the `used_at` field.
  """
  @spec expire_as_used(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def expire_as_used(request) do
    request
    |> expire_as_used_changeset(%{enabled: false, used_at: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Expires all requests that their expiry dates have passed.
  """
  @spec expire_all() :: {:ok, integer()}
  def expire_all do
    now = NaiveDateTime.utc_now()

    # There's a DB index for [:enabled, :expires_at], so filtering for
    # `:enabled` then `:expires_at` should be efficient.
    {num_updated, _} =
      __MODULE__
      |> where([f], f.enabled == true)
      |> where([f], not is_nil(f.expires_at))
      |> where([f], f.expires_at <= ^now)
      |> Repo.update_all([set: [enabled: false]], returning: true)

    {:ok, num_updated}
  end

  @doc """
  Generates a forget password request for the given user.
  """
  @spec generate(%User{}) :: %__MODULE__{} | {:error, Ecto.Changeset.t()}
  def generate(user) do
    token = Crypto.generate_base64_key(@token_length)

    lifetime_minutes =
      Application.get_env(:ewallet, :forget_password_request_lifetime, @default_lifetime_minutes)

    expires_at = NaiveDateTime.utc_now() |> NaiveDateTime.add(60 * lifetime_minutes)

    with {:ok, _} <- insert(%{token: token, user_uuid: user.uuid, expires_at: expires_at}),
         %__MODULE__{} = request <- __MODULE__.get(user, token) do
      {:ok, request}
    else
      error -> error
    end
  end

  defp insert(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
