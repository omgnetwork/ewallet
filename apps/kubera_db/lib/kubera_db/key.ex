defmodule KuberaDB.Key do
  @moduledoc """
  Ecto Schema representing key.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, Key}
  alias KuberaDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @key_bytes 32 # String length = ceil(key_bytes / 3 * 4)

  schema "key" do
    field :access_key, :string
    field :secret_key, :string
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    timestamps()
  end

  @doc """
  Validates key data.
  """
  def changeset(%Key{} = key, attrs) do
    key
    |> cast(attrs, [:access_key, :secret_key, :account_id])
    |> validate_required([:access_key, :secret_key, :account_id])
    |> unique_constraint(:access_key, name: :key_access_key_secret_key_index)
    |> assoc_constraint(:account)
  end

  @doc """
  Creates a new key with the passed attributes.
  Access and/or secret keys are automatically generated if not specified.
  """
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:access_key,
        fn -> Crypto.generate_key(@key_bytes) end)
      |> Map.put_new_lazy(:secret_key,
        fn -> Crypto.generate_key(@key_bytes) end)

    %Key{}
    |> Key.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates using the specified access and secret keys.
  Returns the associated account if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the access/secret key information around.
  """
  def authenticate(access, secret) do
    case get(access, secret) do
      nil ->
        false
      key ->
        key
        |> Repo.preload(:account)
        |> Map.get(:account)
    end
  end

  defp get(access, secret) when is_nil(access) or is_nil(secret), do: nil
  defp get(access, secret) do
    key = Repo.get_by(Key, [access_key: access])

    securely_matched =
      case key do
        %{secret_key: stored_secret} ->
          Crypto.compare(stored_secret, secret)
        _ ->
          false
      end

    # Returns the stored key only if the secret keys securely matched.
    case securely_matched do
      true -> key
      _ -> nil
    end
  end
end
