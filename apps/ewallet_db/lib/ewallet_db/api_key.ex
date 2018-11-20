defmodule EWalletDB.APIKey do
  @moduledoc """
  Ecto Schema representing API key.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use EWalletConfig.Types.ExternalID
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletConfig.Helpers.Crypto
  alias EWalletDB.{Account, APIKey, Repo}

  @primary_key {:uuid, UUID, autogenerate: true}
  # String length = ceil(key_bytes / 3 * 4)
  @key_bytes 32

  schema "api_key" do
    external_id(prefix: "api_")

    field(:key, :string)
    field(:owner_app, :string)

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :exchange_wallet,
      Wallet,
      foreign_key: :exchange_address,
      references: :address,
      type: :string
    )

    field(:enabled, :boolean, default: true)
    timestamps()
    soft_delete()
  end

  defp changeset(%APIKey{} = key, attrs) do
    key
    |> cast(attrs, [:key, :owner_app, :account_uuid, :enabled, :exchange_address])
    |> validate_required([:key, :owner_app, :account_uuid])
    |> unique_constraint(:key)
    |> assoc_constraint(:account)
    |> assoc_constraint(:exchange_wallet)
  end

  defp enable_changeset(%APIKey{} = key, attrs) do
    key
    |> cast(attrs, [:enabled])
    |> validate_required([:enabled])
  end

  defp update_changeset(%APIKey{} = key, attrs) do
    key
    |> cast(attrs, [:enabled, :exchange_address])
    |> validate_required([:enabled])
  end

  @doc """
  Get API key by id, exclude soft-deleted.
  """
  @spec get(String.t()) :: %APIKey{} | nil
  def get(id) when is_external_id(id) do
    APIKey
    |> exclude_deleted()
    |> Repo.get_by(id: id)
  end

  def get(_), do: nil

  @doc """
  Creates a new API key with the passed attributes.
  The key is automatically generated if not specified.
  """
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:account_uuid, fn -> get_master_account_uuid() end)
      |> Map.put_new_lazy(:key, fn -> Crypto.generate_base64_key(@key_bytes) end)

    %APIKey{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an API key with the provided attributes.
  """
  def update(%APIKey{} = api_key, %{"expired" => expired} = attrs) do
    attrs = Map.put(attrs, "enabled", !expired)

    api_key
    |> update_changeset(attrs)
    |> Repo.update()
  end

  def update(%APIKey{} = api_key, attrs) do
    api_key
    |> update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Enable or disable an API key with the provided attributes.
  """
  def enable_or_disable(%APIKey{} = api_key, attrs) do
    api_key
    |> enable_changeset(attrs)
    |> Repo.update()
  end

  defp get_master_account_uuid do
    case Account.get_master_account() do
      %{uuid: uuid} -> uuid
      _ -> nil
    end
  end

  @doc """
  Authenticates using the given API key id and its key.
  Returns the associated account if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the API key information around.
  """
  def authenticate(api_key_id, api_key, owner_app)
      when byte_size(api_key_id) > 0 and byte_size(api_key) > 0 and is_atom(owner_app) do
    api_key_id
    |> get(owner_app)
    |> do_authenticate(api_key)
  end

  def authenticate(_, _, _), do: Crypto.fake_verify()

  defp do_authenticate(%{key: expected_key} = api_key, input_key) do
    case Crypto.secure_compare(expected_key, input_key) do
      true -> api_key
      _ -> false
    end
  end

  defp do_authenticate(nil, _input_key), do: Crypto.fake_verify()

  @doc """
  Authenticates using the given API key (without API key id).
  Returns the associated account if authenticated, false otherwise.

  Note that this is not protected against timing attacks
  and should only be used for non-sensitive requests, e.g. read-only requests.
  """
  def authenticate(api_key, owner_app) when is_atom(owner_app) do
    case get_by_key(api_key, owner_app) do
      %APIKey{} = api_key -> api_key
      nil -> false
    end
  end

  defp get(id, owner_app) when is_binary(id) and is_atom(owner_app) do
    APIKey
    |> Repo.get_by(%{
      id: id,
      owner_app: Atom.to_string(owner_app),
      enabled: true
    })
    |> Repo.preload(:account)
  end

  # Handles unsafe nil query
  defp get_by_key(nil, _), do: nil

  defp get_by_key(key, owner_app) when is_binary(key) and is_atom(owner_app) do
    APIKey
    |> Repo.get_by(%{
      key: key,
      owner_app: Atom.to_string(owner_app),
      enabled: true
    })
    |> Repo.preload(:account)
  end

  @doc """
  Checks whether the given API key is soft-deleted.
  """
  def deleted?(api_key), do: SoftDelete.deleted?(api_key)

  @doc """
  Soft-deletes the given API key.
  """
  def delete(api_key), do: SoftDelete.delete(api_key)

  @doc """
  Restores the given API key from soft-delete.
  """
  def restore(api_key), do: SoftDelete.restore(api_key)
end
