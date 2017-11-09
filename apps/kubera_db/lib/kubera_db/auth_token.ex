defmodule KuberaDB.AuthToken do
  @moduledoc """
  Ecto Schema representing an authentication token.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, AuthToken, User}
  alias KuberaDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @key_length 32

  schema "auth_token" do
    field :token, :string
    belongs_to :user, User, foreign_key: :user_id,
                            references: :id,
                            type: UUID
    field :expired, :boolean
    timestamps()
  end

  @doc """
  Validates auth token data.
  """
  def changeset(%AuthToken{} = token, attrs) do
    token
    |> cast(attrs, [:token, :user_id, :expired])
    |> validate_required([:token, :user_id])
    |> unique_constraint(:token)
    |> assoc_constraint(:user)
  end

  @doc """
  Generate an auth token for the specified user,
  then returns the auth token string.
  """
  def generate(%User{} = user) do
    attrs = %{
      user_id: user.id,
      token: Crypto.generate_key(@key_length)
    }

    {:ok, auth_token} = insert(attrs)
    Map.get(auth_token, :token)
  end
  def generate(_), do: :error

  @doc """
  Retrieves an auth token using the specified token.
  Returns the associated user if authenticated,
  returns :token_expired if token exists but expired,
  returns false otherwise.
  """
  def authenticate(token) do
    case get(token) do
      nil ->
        false
      %{expired: true} ->
        :token_expired
      token ->
        token
        |> Repo.preload(:user)
        |> Map.get(:user)
    end
  end

  # `get/1` is private to prohibit direct auth token access,
  # please use `authenticate/1` instead.
  defp get(token) when is_binary(token) and byte_size(token) > 0 do
    AuthToken
    |> Repo.get_by(token: token)
    |> Repo.preload(:user)
  end
  defp get(_token), do: nil

  # `insert/1` is private to prohibit direct auth token insertion,
  # please use `generate/1` instead.
  defp insert(attrs) do
    %AuthToken{}
    |> AuthToken.changeset(attrs)
    |> Repo.insert()
  end

  # Expires the given token.
  def expire(%AuthToken{} = token),
    do: update(token, %{expired: true})
  def expire(token),
    do: token |> get() |> expire()

  # `insert/1` is private to prohibit direct auth token updates,
  # if expiring the token, please use `expire/1` instead.
  defp update(%AuthToken{} = token, attrs) do
    token
    |> AuthToken.changeset(attrs)
    |> Repo.update()
  end
end
