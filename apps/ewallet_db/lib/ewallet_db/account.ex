# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.Account do
  @moduledoc """
  Ecto Schema representing account.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Utils.Helpers.InputAttribute
  alias Ecto.{Multi, UUID}

  alias EWalletDB.{
    Account,
    AccountUser,
    APIKey,
    Category,
    Key,
    Membership,
    Repo,
    Token,
    User,
    Wallet
  }

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "account" do
    external_id(prefix: "acc_")

    field(:name, :string)
    field(:description, :string)
    field(:avatar, EWalletDB.Uploaders.Avatar.Type)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletDB.Encrypted.Map, default: %{})

    many_to_many(
      :categories,
      Category,
      join_through: "account_category",
      join_keys: [account_uuid: :uuid, category_uuid: :uuid],
      on_replace: :delete
    )

    has_many(
      :wallets,
      Wallet,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :tokens,
      Token,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :keys,
      Key,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :api_keys,
      APIKey,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :memberships,
      Membership,
      foreign_key: :account_uuid,
      references: :uuid
    )

    timestamps()
    activity_logging()
  end

  @spec changeset(%Account{}, map()) :: Ecto.Changeset.t()
  defp changeset(%Account{} = account, attrs) do
    account
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:name, :description, :metadata, :encrypted_metadata],
      required: [:name],
      encrypted: [:encrypted_metadata]
    )
    |> unique_constraint(:name)
    |> put_categories(attrs, :category_ids)
  end

  defp put_categories(changeset, attrs, attr_name) do
    case InputAttribute.get(attrs, attr_name) do
      ids when is_list(ids) ->
        put_categories(changeset, ids)

      _ ->
        changeset
    end
  end

  defp put_categories(changeset, category_ids) do
    # Associations need to be preloaded before updating
    changeset = Map.put(changeset, :data, Repo.preload(changeset.data, :categories))
    categories = Repo.all(from(c in Category, where: c.id in ^category_ids))
    put_assoc(changeset, :categories, categories)
  end

  @spec avatar_changeset(Ecto.Changeset.t() | %Account{}, map()) ::
          Ecto.Changeset.t() | %Account{} | no_return()
  defp avatar_changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(attrs)
    |> cast_attachments(attrs, [:avatar])
  end

  @doc """
  Create a new account with the passed attributes, as well as a primary and a burn wallets.
  """
  @spec insert(map()) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %Account{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log(
      [],
      Multi.new()
      |> Multi.run(:wallet, fn _repo, %{record: account} ->
        _ = insert_wallet(account, Wallet.primary())
        insert_wallet(account, Wallet.burn())
      end)
    )
    |> case do
      {:ok, account} ->
        {:ok, Repo.preload(account, [:wallets])}

      error ->
        error
    end
  end

  @doc """
  Updates an account with the provided attributes.
  """
  @spec update(%Account{}, map()) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def update(%Account{} = account, attrs) do
    changeset = changeset(account, attrs)

    case Repo.update_record_with_activity_log(changeset) do
      {:ok, account} ->
        {:ok, get(account.id)}

      result ->
        result
    end
  end

  @doc """
  Inserts a wallet for the given account.
  """
  @spec insert_wallet(%Account{}, String.t()) :: {:ok, %Wallet{}} | {:error, Ecto.Changeset.t()}
  def insert_wallet(%Account{} = account, identifier) do
    %{
      account_uuid: account.uuid,
      name: identifier,
      identifier: identifier,
      metadata: %{},
      originator: account
    }
    |> Wallet.insert()
  end

  @doc """
  Stores an avatar for the given account.
  """
  @spec store_avatar(%Account{}, map()) :: %Account{} | nil | no_return()
  def store_avatar(%Account{} = account, %{"originator" => originator} = attrs) do
    attrs =
      attrs["avatar"]
      |> case do
        "" -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end
      |> Map.put(:originator, originator)

    changeset = avatar_changeset(account, attrs)

    case Repo.update_record_with_activity_log(changeset) do
      {:ok, account} -> get(account.id)
      result -> result
    end
  end

  @doc """
  Get all accounts.
  """
  @spec all(keyword()) :: list(%Account{})
  def all(opts \\ [])

  def all(opts) do
    Account
    |> Repo.all()
    |> preload_option(opts)
  end

  def where_in(query, uuids) do
    where(query, [a], a.uuid in ^uuids)
  end

  @doc """
  Retrieves an account with the given ID.
  """
  @spec get(String.t(), keyword()) :: %Account{} | nil | no_return()
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an account using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %Account{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    Account
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Returns whether the account is the master account.
  """
  @spec master?(%Account{}) :: boolean()
  def master?(account) do
    Application.get_env(:ewallet_db, :master_account) == account.uuid
  end

  @doc """
  Get the master account for the current wallet setup.
  """
  @spec get_master_account(keyword()) :: %Account{} | nil
  def get_master_account(opts \\ []) do
    uuid = Application.get_env(:ewallet_db, :master_account)

    case UUID.cast(uuid) do
      {:ok, uuid} ->
        get_by([uuid: uuid], opts)

      _ ->
        nil
    end
  end

  @doc """
  Fetches the master account for the current eWallet setup.

  Returns `{:ok, account}` when successful, or `{:error, :missing_master_account}` on failure.
  """
  @spec fetch_master_account(keyword()) :: {:ok, %Account{}} | {:error, :missing_master_account}
  def fetch_master_account(opts \\ []) do
    case get_master_account(opts) do
      %__MODULE__{} = account ->
        {:ok, account}

      _ ->
        {:error, :missing_master_account}
    end
  end

  @doc """
  Retrieve the primary wallet for an account with preloaded wallets.
  """
  @spec get_preloaded_primary_wallet(%Account{}) :: %Wallet{} | nil
  def get_preloaded_primary_wallet(account) do
    Enum.find(account.wallets, fn wallet -> wallet.identifier == Wallet.primary() end)
  end

  @doc """
  Retrieve the primary wallet for an account.
  """
  @spec get_primary_wallet(%Account{}) :: %Wallet{}
  def get_primary_wallet(account) do
    get_wallet_by_identifier(account, Wallet.primary())
  end

  @doc """
  Retrieve the default burn wallet for an account.
  """
  @spec get_default_burn_wallet(%Account{}) :: %Wallet{}
  def get_default_burn_wallet(account) do
    get_wallet_by_identifier(account, Wallet.burn())
  end

  @doc """
  Retrieve a wallet by name for the given account.
  """
  @spec get_wallet_by_identifier(%Account{}, String.t()) :: %Wallet{} | nil | no_return()
  def get_wallet_by_identifier(account, identifier) do
    Wallet
    |> where([b], b.identifier == ^identifier)
    |> where([b], b.account_uuid == ^account.uuid)
    |> Repo.one()
  end

  def get_all_users(account_uuids) do
    User
    |> query_all_users(account_uuids)
    |> Repo.all()
  end

  def query_all_users(query, account_uuids) do
    from(
      user in query,
      join: account_user in AccountUser,
      on: account_user.user_uuid == user.uuid,
      distinct: true,
      where: account_user.account_uuid in ^account_uuids
    )
  end

  @spec add_category(%Account{}, %Category{}, map()) ::
          {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def add_category(account, category, originator) do
    account = Repo.preload(account, :categories)

    category_ids =
      account
      |> Map.fetch!(:categories)
      |> Enum.map(fn existing -> existing.id end)
      |> List.insert_at(0, category.id)

    Account.update(account, %{
      category_ids: category_ids,
      originator: originator
    })
  end

  @spec remove_category(%Account{}, %Category{}, map()) ::
          {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def remove_category(account, category, originator) do
    account = Repo.preload(account, :categories)

    remaining =
      Enum.reject(account.categories, fn existing ->
        existing.id == category.id
      end)

    category_ids = Enum.map(remaining, fn c -> c.id end)

    Account.update(account, %{
      category_ids: category_ids,
      originator: originator
    })
  end
end
