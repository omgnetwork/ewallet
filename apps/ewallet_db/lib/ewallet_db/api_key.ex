defmodule EWalletDB.APIKey do
  @moduledoc """
  Ecto Schema representing API key.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account, APIKey}
  alias EWalletDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}
  @key_bytes 32 # String length = ceil(key_bytes / 3 * 4)

  schema "api_key" do
    field :key, :string
    field :owner_app, :string
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    field :expired, :boolean
    timestamps()
  end

  defp changeset(%APIKey{} = key, attrs) do
    key
    |> cast(attrs, [:key, :owner_app, :account_id, :expired])
    |> validate_required([:key, :owner_app, :account_id])
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
  Authenticates using the given API key id and its key.
  Returns the associated account if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the API key information around.
  """
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
  def authenticate(api_key, owner_app) when is_atom(owner_app) do
    case get_by_key(api_key, owner_app) do
      %APIKey{} = api_key -> Map.get(api_key, :account)
      nil -> false
    end
  end

  defp get(nil, _), do: nil # Handles unsafe nil query
  defp get(id, owner_app) when is_binary(id) and is_atom(owner_app) do
    APIKey
    |> Repo.get_by(%{
      id: id,
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
end
