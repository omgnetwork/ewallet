defmodule ActivityLogger.TestUser do
  @moduledoc """
  Ecto Schema representing test documents.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  alias Ecto.{Multi, UUID}
  alias ActivityLogger.{TestDocument, Repo, TestUser}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "test_user" do
    external_id(prefix: "tus_")

    field(:username, :string)

    timestamps()
    activity_logging()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      [:username],
      [:username]
    )
  end

  @spec insert(map()) :: {:ok, %TestUser{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %TestUser{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log([])
  end

  def insert_with_document(attrs) do
    %TestUser{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log(
      [],
      Multi.run(Multi.new(), :document, fn %{record: record} ->
        TestDocument.insert(%{
          title: record.username,
          originator: record
        })
      end)
    )
  end

  @doc """
  Updates a user with the provided attributes.
  """
  @spec update(%TestUser{}, map()) :: {:ok, %TestUser{}} | {:error, Ecto.Changeset.t()}
  def update(%TestUser{} = user, attrs) do
    user
    |> changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end
end
