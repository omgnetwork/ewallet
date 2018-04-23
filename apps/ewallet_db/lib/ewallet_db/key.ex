defmodule EWalletDB.Key do
  @moduledoc """
  Ecto Schema representing key.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account, Key, Helpers.Crypto}

  @primary_key {:uuid, UUID, autogenerate: true}
  @key_bytes 32 # String length = ceil(key_bytes / 3 * 4)

  schema "key" do
    external_id prefix: "key_"

    field :access_key, :string
    field :secret_key, :string, virtual: true
    field :secret_key_hash, :string
    belongs_to :account, Account, foreign_key: :account_uuid,
                                  references: :uuid,
                                  type: UUID
    timestamps()
    soft_delete()
  end

  defp changeset(%Key{} = key, attrs) do
    key
    |> cast(attrs, [:access_key, :secret_key, :account_uuid])
    |> validate_required([:access_key, :secret_key, :account_uuid])
    |> unique_constraint(:access_key, name: :key_access_key_index)
    |> put_change(:secret_key_hash, Crypto.hash_password(attrs[:secret_key]))
    |> assoc_constraint(:account)
  end

  @doc """
  Get all keys, exclude soft-deleted.
  """
  def all do
    Key
    |> exclude_deleted()
    |> Repo.all()
  end

  @doc """
  Get key by id, exclude soft-deleted.
  """
  @spec get(ExternalID.t) :: %Key{} | nil
  def get(id)
  def get(id) when is_external_id(id) do
    Key
    |> exclude_deleted()
    |> Repo.get_by(id: id)
  end
  def get(_), do: nil

  @doc """
  Get key by its `:access_key`, exclude soft-deleted.
  """
  def get(:access_key, access_key) do
    Key
    |> exclude_deleted()
    |> Repo.get_by(access_key: access_key)
  end

  @doc """
  Creates a new key with the passed attributes.

  The `account_uuid` defaults to the master account if not provided.
  The `access_key` and `secret_key` are automatically generated if not specified.
  """
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:account_uuid, fn -> get_master_account_uuid() end)
      |> Map.put_new_lazy(:access_key, fn -> Crypto.generate_key(@key_bytes) end)
      |> Map.put_new_lazy(:secret_key, fn -> Crypto.generate_key(@key_bytes) end)

    %Key{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp get_master_account_uuid do
    case Account.get_master_account() do
      %{uuid: uuid} -> uuid
      _ -> nil
    end
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
    |> Repo.all()
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

  @doc """
  Checks whether the given key is soft-deleted.
  """
  def deleted?(key), do: SoftDelete.deleted?(key)

  @doc """
  Soft-deletes the given key.
  """
  def delete(key), do: SoftDelete.delete(key)

  @doc """
  Restores the given key from soft-delete.
  """
  def restore(key), do: SoftDelete.restore(key)
end
