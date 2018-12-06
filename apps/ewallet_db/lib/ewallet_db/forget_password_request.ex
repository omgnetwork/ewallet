defmodule EWalletDB.ForgetPasswordRequest do
  @moduledoc """
  Ecto Schema representing a password reset request.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletDB.{ForgetPasswordRequest, Repo, User}
  alias Utils.Helpers.Crypto
  alias ActivityLogger.System

  @primary_key {:uuid, UUID, autogenerate: true}
  @token_length 32

  schema "forget_password_request" do
    field(:token, :string)
    field(:enabled, :boolean)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
    activity_logging()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:token, :user_uuid],
      required: [
        :token,
        :user_uuid
      ]
    )
    |> assoc_constraint(:user)
  end

  @doc """
  Retrieves all active requests.
  """
  @spec all_active() :: [%ForgetPasswordRequest{}]
  def all_active do
    ForgetPasswordRequest
    |> where([c], c.enabled == true)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  @doc """
  Retrieves a specific invite by its token.
  """
  @spec get(%User{} | nil, String.t() | nil) :: %ForgetPasswordRequest{} | nil
  def get(nil, _), do: nil
  def get(_, nil), do: nil

  def get(user, token) do
    request =
      ForgetPasswordRequest
      |> where([c], c.user_uuid == ^user.uuid)
      |> where([c], c.enabled == true)
      |> order_by([c], desc: c.inserted_at)
      |> limit(1)
      |> Repo.one()
      |> Repo.preload(:user)

    check_token(request, token)
  end

  defp check_token(nil, _token), do: nil

  defp check_token(request, token) do
    if Crypto.secure_compare(request.token, token), do: request, else: nil
  end

  @doc """
  Deletes all the current requests for a user.
  """
  @spec disable_all_for(%User{}) :: {integer(), nil}
  def disable_all_for(user) do
    ForgetPasswordRequest
    |> where([f], f.user_uuid == ^user.uuid)
    |> Repo.update_all(set: [enabled: false])
  end

  @doc """
  Generates a forget password request for the given user.
  """
  @spec generate(%User{}) :: %ForgetPasswordRequest{} | {:error, Ecto.Changeset.t()}
  def generate(user) do
    token = Crypto.generate_base64_key(@token_length)

    {:ok, _} =
      insert(%{
        token: token,
        user_uuid: user.uuid,
        originator: %System{}
      })

    ForgetPasswordRequest.get(user, token)
  end

  defp insert(attrs) do
    %ForgetPasswordRequest{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end
end
