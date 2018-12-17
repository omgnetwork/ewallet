defmodule EWalletDB.Export do
  @moduledoc """
  Ecto Schema representing audits.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import EWalletConfig.Validator
  import Ecto.{Changeset, Query}
  alias Ecto.{Changeset, Multi, UUID}

  alias EWalletDB.{
    Export,
    Repo,
    User,
    Key
  }

  @new "new"
  @processing "processing"
  @completed "completed"
  @failed "failed"

  def new, do: @new
  def processing, do: @processing
  def completed, do: @completed
  def failed, do: @failed

  @default_format "csv"
  @formats ["csv"]

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "export" do
    external_id(prefix: "exp_")

    field(:schema, :string)
    field(:format, :string, default: @default_format)
    field(:status, :string)
    field(:completion, :integer)
    field(:url, :string)
    # filename
    # failure reason
    # estimated size
    # actual size
    # adapter
    field(:params, :map)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :key,
      Key,
      foreign_key: :key_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
    activity_logging()
  end

  defp create_changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :schema,
        :status,
        :completion,
        :url,
        :params,
        :user_uuid,
        :key_uuid
      ],
      required: [
        :schema,
        :status,
        :completion,
        :params,
      ]
    )
    |> validate_required_exclusive([:user_uuid, :key_uuid])
    |> validate_inclusion(:format, @formats)
    |> validate_inclusion(:status, [@new, @processing, @completed, @failed])
    |> assoc_constraint(:user)
    |> assoc_constraint(:key)
  end

  defp update_changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :status,
        :completion,
        :url
      ],
      required: [
        :status,
        :completion
      ]
    )
    |> validate_inclusion(:status, [@new, @processing, @completed, @failed])
  end

  @doc """

  """
  @spec insert(map()) :: {:ok, %Export{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %Export{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """

  """
  # TODO spec
  def update(%Export{} = export, attrs) do
    export
    |> update_changeset(attrs)
    |> Repo.update()
  end
end
