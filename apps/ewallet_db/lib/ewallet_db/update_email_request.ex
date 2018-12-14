defmodule EWalletDB.UpdateEmailRequest do
  @moduledoc """
  Ecto Schema representing a change email request.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.UUID
  alias Utils.Helpers.Crypto
  alias EWalletDB.{UpdateEmailRequest, Repo, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @token_length 32

  schema "update_email_request" do
    field(:email, :string)
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
      cast: [:email, :token, :user_uuid],
      required: [:email, :token, :user_uuid]
    )
    |> validate_email(:email)
    |> unique_constraint(:token)
    |> assoc_constraint(:user)
  end

  @doc """
  Retrieves all active requests.
  """
  def all_active do
    UpdateEmailRequest
    |> where([c], c.enabled == true)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  @doc """
  Retrieves a specific invite by its token.
  """
  @spec get(String.t() | nil, String.t() | nil) :: %__MODULE__{} | nil
  def get(nil, _), do: nil
  def get(_, nil), do: nil

  def get(email, token) do
    request =
      UpdateEmailRequest
      |> where([c], c.email == ^email)
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
  def disable_all_for(user) do
    UpdateEmailRequest
    |> where([f], f.user_uuid == ^user.uuid)
    |> Repo.update_all(set: [enabled: false])
  end

  @doc """
  Generates a change email request for the given user.
  """
  @spec generate(%User{}, String.t()) :: %UpdateEmailRequest{} | {:error, Changeset.t()}
  def generate(user, email) do
    token = Crypto.generate_base64_key(@token_length)

    {:ok, _} =
      insert(%{
        token: token,
        email: email,
        user_uuid: user.uuid,
        originator: user
      })

    UpdateEmailRequest.get(email, token)
  end

  defp insert(attrs) do
    %UpdateEmailRequest{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end
end
