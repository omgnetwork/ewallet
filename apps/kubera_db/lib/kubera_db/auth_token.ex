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
  Handles unsafe nil values so Ecto does not throw warnings.
  """
  def authenticate(token) do
    case get(token) do
      nil ->
        false
      token ->
        token
        |> Repo.preload(:user)
        |> Map.get(:user)
    end
  end

  # `get/1` is private to prohibit direct auth token access,
  # please use `authenticate/1` instead.
  defp get(token) when is_nil(token), do: nil
  defp get(token) do
    AuthToken
    |> Repo.get_by([token: token, expired: false])
    |> Repo.preload(:user)
  end

  # `insert/1` is private to prohibit direct auth token insertion,
  # please use `generate/1` instead.
  defp insert(attrs) do
    %AuthToken{}
    |> AuthToken.changeset(attrs)
    |> Repo.insert()
  end
end
