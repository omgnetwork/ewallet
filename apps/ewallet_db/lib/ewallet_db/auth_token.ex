# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.AuthToken do
  @moduledoc """
  Ecto Schema representing an authentication token.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Ecto.UUID
  alias Utils.Helpers.Crypto
  alias EWalletDB.Expirers.AuthExpirer
  alias EWalletDB.{Account, AuthToken, Repo, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]
  @key_length 32

  schema "auth_token" do
    external_id(prefix: "atk_")

    field(:token, :string)
    field(:owner_app, :string)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    field(:expired, :boolean)
    field(:expired_at, :naive_datetime_usec)
    timestamps()
    activity_logging()
  end

  defp changeset(%AuthToken{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:token, :owner_app, :user_uuid, :account_uuid, :expired, :expired_at],
      required: [:token, :owner_app, :user_uuid]
    )
    |> unique_constraint(:token)
    |> assoc_constraint(:user)
  end

  defp expire_changeset(%AuthToken{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:expired, :expired_at],
      required: [:expired]
    )
  end

  defp switch_account_changeset(%AuthToken{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:account_uuid],
      required: [:account_uuid]
    )
  end

  @spec switch_account(%__MODULE__{}, %Account{}, map()) ::
          {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def switch_account(token, account, originator) do
    token
    |> switch_account_changeset(%{
      account_uuid: account.uuid,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Generate an auth token for the specified user,
  then returns the auth token string.
  """
  @spec generate(%User{}, atom(), any()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def generate(%User{} = user, owner_app, originator) when is_atom(owner_app) do
    %{
      owner_app: Atom.to_string(owner_app),
      user_uuid: user.uuid,
      account_uuid: nil,
      expired_at: get_lifetime() |> AuthExpirer.get_advanced_datetime(),
      token: Crypto.generate_base64_key(@key_length),
      originator: originator
    }
    |> insert()
  end

  def generate(_, _, _), do: {:error, :invalid_parameter}

  @doc """
  Retrieves an auth token using the specified token.
  Returns the associated user if authenticated, :token_expired if token exists but expired,
  or false otherwise.
  """
  @spec authenticate(String.t(), atom()) ::
          %User{}
          | {:error, :token_not_found}
          | {:error, :token_expired}
          | {:error, Ecto.Changeset.t()}
  def authenticate(token, owner_app) when is_atom(owner_app) do
    token
    |> get_by_token(owner_app)
    |> AuthExpirer.expire_or_refresh(get_lifetime())
    |> return_user()
  end

  @spec authenticate(String.t(), String.t(), atom()) ::
          %User{}
          | {:error, :token_not_found}
          | {:error, :token_expired}
          | {:error, Ecto.Changeset.t()}
  def authenticate(user_id, token, owner_app) when is_atom(owner_app) do
    user_id
    |> get_by_user(owner_app)
    |> compare_multiple(token)
    |> AuthExpirer.expire_or_refresh(get_lifetime())
    |> return_user()
  end

  def authenticate(_, _, _), do: Crypto.fake_verify()

  defp compare_multiple(_, nil), do: nil

  defp compare_multiple(token_records, token) when is_list(token_records) do
    Enum.find(token_records, fn record ->
      Crypto.secure_compare(record.token, token)
    end)
  end

  defp return_user(token) do
    case token do
      nil ->
        {:error, :token_not_found}

      {:error, changeset} ->
        {:error, changeset}

      %{expired: true} ->
        {:error, :token_expired}

      token ->
        token
        |> Repo.preload(:user)
        |> Map.get(:user)
    end
  end

  @spec get_by_token(String.t(), atom()) :: %__MODULE__{} | nil
  def get_by_token(token, owner_app) when is_binary(token) and is_atom(owner_app) do
    AuthToken
    |> Repo.get_by(%{
      token: token,
      owner_app: Atom.to_string(owner_app)
    })
    |> Repo.preload(:user)
  end

  def get_by_token(_, _), do: nil

  # `get_by_user/2` is private to prohibit direct auth token access,
  # please use `authenticate/3` instead.
  defp get_by_user(user_id, owner_app) when is_binary(user_id) and is_atom(owner_app) do
    auth_tokens =
      Repo.all(
        from(
          a in AuthToken,
          join: u in User,
          on: u.uuid == a.user_uuid,
          where: u.id == ^user_id and a.owner_app == ^Atom.to_string(owner_app)
        )
      )

    Repo.preload(auth_tokens, :user)
  end

  defp get_by_user(_, _), do: nil

  @spec get_lifetime() :: integer
  def get_lifetime, do: Application.get_env(:ewallet_db, :auth_token_lifetime, 0)

  # `insert/1` is private to prohibit direct auth token insertion,
  # please use `generate/2` instead.
  defp insert(attrs) do
    %AuthToken{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  # Expires the given token.
  @spec expire(String.t(), atom(), any()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def expire(token, owner_app, originator) when is_binary(token) and is_atom(owner_app) do
    token
    |> get_by_token(owner_app)
    |> expire(originator)
  end

  def expire(%AuthToken{} = token, originator) do
    update(:expire, token, %{
      expired: true,
      originator: originator
    })
  end

  @spec expire_for_user(atom() | %User{}) :: :ok
  def expire_for_user(%{enabled: true}), do: :ok

  def expire_for_user(user) do
    Repo.update_all(
      from(
        a in AuthToken,
        where: a.user_uuid == ^user.uuid
      ),
      set: [expired: true]
    )

    :ok
  end

  @spec refresh(%__MODULE__{}, any()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def refresh(%AuthToken{} = token, originator) do
    update(:refresh, token, %{
      expired: false,
      expired_at: get_lifetime() |> AuthExpirer.get_advanced_datetime(),
      originator: originator
    })
  end

  @doc """
  Delete all AuthTokens associated with the user.
  """
  @spec delete_for_user(%User{}) :: :ok
  def delete_for_user(user) do
    Repo.delete_all(
      from(
        a in AuthToken,
        where: a.user_uuid == ^user.uuid
      )
    )

    :ok
  end

  defp update(operation, %AuthToken{} = token, attrs) do
    token
    |> expire_changeset(attrs)
    |> do_update(operation)
  end

  defp do_update(changeset, :refresh), do: Repo.update(changeset)
  defp do_update(changeset, :expire), do: Repo.update_record_with_activity_log(changeset)
  defp do_update(changeset, _), do: Repo.update_record_with_activity_log(changeset)
end
