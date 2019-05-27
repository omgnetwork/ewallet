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

defmodule EWalletDB.PreAuthToken do
  @moduledoc """
  Ecto Schema representing a pre authentication token.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Ecto.UUID
  alias Utils.Helpers.Crypto
  alias EWalletDB.Expirers.AuthExpirer
  alias EWalletDB.{Account, PreAuthToken, Repo, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]
  @key_length 32

  schema "pre_auth_token" do
    external_id(prefix: "ptk_")

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
    field(:expire_at, :naive_datetime_usec)
    timestamps()
    activity_logging()
  end

  defp changeset(%PreAuthToken{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:token, :owner_app, :user_uuid, :account_uuid, :expired, :expire_at],
      required: [:token, :owner_app, :user_uuid]
    )
    |> unique_constraint(:token)
    |> assoc_constraint(:user)
  end

  defp expire_changeset(%PreAuthToken{} = token, attrs) do
    token
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:expired, :expire_at],
      required: [:expired]
    )
  end

  @doc """
  Generate a pre auth token for the specified user to be used for verify two-factor auth,
  then returns the pre auth token string.
  """
  def generate(%User{} = user, owner_app, originator) when is_atom(owner_app) do
    %{
      owner_app: Atom.to_string(owner_app),
      user_uuid: user.uuid,
      account_uuid: nil,
      expire_at: get_lifetime() |> AuthExpirer.get_advanced_datetime(),
      token: Crypto.generate_base64_key(@key_length),
      originator: originator
    }
    |> insert()
  end

  def generate(_, _, _), do: {:error, :invalid_parameter}

  @doc """
  Retrieves a pre auth token using the specified token.
  Returns the associated user if authenticated, :token_expired if token exists but expired,
  or false otherwise.
  """
  def authenticate(token, owner_app) when is_atom(owner_app) do
    token
    |> get_by_token(owner_app)
    |> AuthExpirer.expire_or_refresh(get_lifetime())
    |> return_token_if_valid()
  end

  def authenticate(user_id, token, owner_app) when token != nil and is_atom(owner_app) do
    user_id
    |> get_by_user(owner_app)
    |> compare_multiple(token)
    |> AuthExpirer.expire_or_refresh(get_lifetime())
    |> return_token_if_valid()
  end

  def authenticate(_, _, _), do: Crypto.fake_verify()

  defp compare_multiple(token_records, token) when is_list(token_records) do
    Enum.find(token_records, fn record ->
      Crypto.secure_compare(record.token, token)
    end)
  end

  defp return_token_if_valid(token) do
    case token do
      nil ->
        false

      {:error, _} ->
        false

      %{expired: true} ->
        :token_expired

      token ->
        Repo.preload(token, :user)
    end
  end

  @spec get_by_token(String.t(), atom()) :: %__MODULE__{} | nil
  def get_by_token(token, owner_app) when is_binary(token) and is_atom(owner_app) do
    PreAuthToken
    |> Repo.get_by(%{
      token: token,
      owner_app: Atom.to_string(owner_app)
    })
    |> Repo.preload(:user)
  end

  def get_by_token(_, _), do: nil

  # `get_by_user/2` is private to prohibit direct pre auth token access,
  # please use `authenticate/3` instead.
  defp get_by_user(user_id, owner_app) when is_binary(user_id) and is_atom(owner_app) do
    auth_tokens =
      Repo.all(
        from(
          a in PreAuthToken,
          join: u in User,
          on: u.uuid == a.user_uuid,
          where: u.id == ^user_id and a.owner_app == ^Atom.to_string(owner_app)
        )
      )

    Repo.preload(auth_tokens, :user)
  end

  defp get_by_user(_, _), do: nil

  # def get_lifetime(), do: Setting.get(@key_ptk_lifetime).value
  def get_lifetime, do: Application.get_env(:ewallet_db, :ptk_lifetime, 0)

  # `insert/1` is private to prohibit direct pre auth token insertion,
  # please use `generate/2` instead.
  defp insert(attrs) do
    %PreAuthToken{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Delete all PreAuthTokens associated with the user.
  """
  def delete_for_user(user) do
    Repo.delete_all(
      from(
        a in PreAuthToken,
        where: a.user_uuid == ^user.uuid
      )
    )

    :ok
  end

  # Expires the given token.
  @spec expire(binary(), atom(), any()) :: {:error, any()} | {:ok, any()}
  def expire(token, owner_app, originator) when is_binary(token) and is_atom(owner_app) do
    token
    |> get_by_token(owner_app)
    |> expire(originator)
  end

  @spec expire(EWalletDB.PreAuthToken.t(), any()) :: {:error, any()} | {:ok, any()}
  def expire(%PreAuthToken{} = token, originator) do
    update(token, %{
      expired: true,
      originator: originator
    })
  end

  def refresh(%PreAuthToken{} = token, originator) do
    update(token, %{
      expire_at: get_lifetime() |> AuthExpirer.get_advanced_datetime(),
      originator: originator
    })
  end

  # if expiring the token, please use `expire/2` instead.
  defp update(%PreAuthToken{} = token, attrs) do
    token
    |> expire_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end
end
