defmodule KuberaDB.APIKey do
  @moduledoc """
  Ecto Schema representing API key.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, APIKey}
  alias KuberaDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @key_bytes 32 # String length = ceil(key_bytes / 3 * 4)

  schema "api_key" do
    field :key, :string
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    field :expired, :boolean
    timestamps()
  end

  defp changeset(%APIKey{} = key, attrs) do
    key
    |> cast(attrs, [:key, :account_id, :expired])
    |> validate_required([:key, :account_id])
    |> unique_constraint(:key)
    |> assoc_constraint(:account)
  end

  @doc """
  Creates a new API key with the passed attributes.
  The key is automatically generated if not specified.
  """
  def insert(attrs) do
    attrs = Map.put_new_lazy(attrs, :key,
      fn -> Crypto.generate_key(@key_bytes) end
    )

    %APIKey{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates using the specified access and secret keys.
  Returns the associated account if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the access/secret key information around.
  """
  def authenticate(api_key) do
    case get(api_key) do
      nil ->
        false
      api_key ->
        api_key
        |> Repo.preload(:account)
        |> Map.get(:account)
    end
  end

  # Handles unsafe nil values so Ecto does not throw warnings.
  defp get(key) when is_nil(key), do: nil
  defp get(key) do
    APIKey
    |> Repo.get_by([key: key, expired: false])
    |> Repo.preload(:account)
  end
end
