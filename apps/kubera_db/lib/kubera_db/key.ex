defmodule KuberaDB.Key do
  @moduledoc """
  Ecto Schema representing key.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, Key}
  alias KuberaDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @key_bytes 32 # String length = ceil(key_bytes / 3 * 4)

  schema "key" do
    field :access_key, :string
    field :secret_key, :string, virtual: true
    field :secret_key_hash, :string
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
    |> unique_constraint(:access_key, name: :key_access_key_index)
    |> put_change(:secret_key_hash, Crypto.hash_password(attrs[:secret_key]))
    |> assoc_constraint(:account)
  end

  @doc """
  Creates a new key with the passed attributes.
  Access and/or secret keys are automatically generated if not specified.
  """
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:access_key, fn -> Crypto.generate_key(@key_bytes) end)
      |> Map.put_new_lazy(:secret_key, fn -> Crypto.generate_key(@key_bytes) end)

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
  def authenticate(access, secret)
    when is_binary(access)
    and is_binary(secret)
  do
    query =
      from(k in Key,
        where: k.access_key == ^access,
        join: a in assoc(k, :account),
        preload: [account: a])

    query
    |> KuberaDB.Repo.all()
    |> Enum.at(0)
    |> authenticate(secret)
  end

  def authenticate(%{secret_key_hash: secret_key_hash} = key, secret) do
    case Crypto.verify_password(secret, secret_key_hash) do
      true -> Map.get(key, :account)
      _ -> false
    end
  end

  # Deliberately slow down invalid query to make user enumeration harder.
  #
  # There is still timing leak when the query wasn't called due to either
  # access or secret being nil, but no enumeration could took place in
  # such cases.
  #
  # There is also timing leak due to fake_verify not performing comparison
  # (only performing Bcrypt hash operation) which may be a problem.
  def authenticate(_, _) do
    Crypto.fake_verify
  end
end
