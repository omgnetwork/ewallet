defmodule EWalletDB.APIKey do
  @moduledoc """
  Ecto Schema representing API key.
  """
  use EWalletDB.Schema
  alias EWalletDB.{Account, APIKey}
  alias EWalletDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @key_bytes 32 # String length = ceil(key_bytes / 3 * 4)

  schema "api_key" do
    external_id prefix: "api_"

    field :key, :string
    field :owner_app, :string
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    field :expired, :boolean
    timestamps()
    soft_delete()
  end

  defp changeset(%APIKey{} = key, attrs) do
    key
    |> cast(attrs, [:key, :owner_app, :account_id, :expired])
    |> validate_required([:key, :owner_app, :account_id])
    |> unique_constraint(:key)
    |> assoc_constraint(:account)
  end

  @doc """
  Retrieves an API key by the given `external_id`. Excludes soft-deleted.
  """
  @spec get(ExternalID.t() | nil) :: __MODULE__.t() | nil
  def get(nil), do: nil
  def get(external_id) do
    APIKey
    |> exclude_deleted()
    |> Repo.get_by(external_id: external_id)
  end

  @doc """
  Creates a new API key with the passed attributes.
  The key is automatically generated if not specified.
  """
  @spec insert(map()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:account_id, fn -> get_master_account_id() end)
      |> Map.put_new_lazy(:key, fn -> Crypto.generate_key(@key_bytes) end)

    %APIKey{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp get_master_account_id do
    case Account.get_master_account() do
      %{id: id} -> id
      _ -> nil
    end
  end

  @doc """
  Authenticates using the given API key id and its key.
  Returns the associated account if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the API key information around.
  """
  @spec authenticate(ExternalID.t(), String.t(), atom()) :: %Account{} | false
  def authenticate(api_key_id, api_key, owner_app)
    when byte_size(api_key_id) > 0
    and byte_size(api_key) > 0
    and is_atom(owner_app)
  do
    api_key_id
    |> get(owner_app)
    |> do_authenticate(api_key)
  end
  def authenticate(_, _, _), do: Crypto.fake_verify

  defp do_authenticate(%{key: expected_key} = api_key, input_key) do
    case Crypto.secure_compare(expected_key, input_key) do
      true -> Map.get(api_key, :account)
      _ -> false
    end
  end
  defp do_authenticate(nil, _input_key), do: Crypto.fake_verify

  @doc """
  Authenticates using the given API key (without API key id).
  Returns the associated account if authenticated, false otherwise.

  Note that this is not protected against timing attacks
  and should only be used for non-sensitive requests, e.g. read-only requests.
  """
  @spec authenticate(String.t(), atom()) :: Account.t() | false
  def authenticate(api_key, owner_app) when is_atom(owner_app) do
    case get_by_key(api_key, owner_app) do
      %APIKey{} = api_key -> Map.get(api_key, :account)
      nil -> false
    end
  end

  defp get(nil, _), do: nil # Handles unsafe nil query
  defp get(external_id, owner_app) when is_binary(external_id) and is_atom(owner_app) do
    APIKey
    |> Repo.get_by(%{
      external_id: external_id,
      owner_app: Atom.to_string(owner_app),
      expired: false
    })
    |> Repo.preload(:account)
  end

  defp get_by_key(nil, _), do: nil # Handles unsafe nil query
  defp get_by_key(key, owner_app) when is_binary(key) and is_atom(owner_app) do
    APIKey
    |> Repo.get_by(%{
      key: key,
      owner_app: Atom.to_string(owner_app),
      expired: false
    })
    |> Repo.preload(:account)
  end

  @doc """
  Checks whether the given API key is soft-deleted.
  """
  @spec deleted?(__MODULE__.t()) :: boolean()
  def deleted?(api_key), do: SoftDelete.deleted?(api_key)

  @doc """
  Soft-deletes the given API key.
  """
  @spec delete(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def delete(api_key), do: SoftDelete.delete(api_key)

  @doc """
  Restores the given API key from soft-delete.
  """
  @spec restore(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def restore(api_key), do: SoftDelete.restore(api_key)
end
