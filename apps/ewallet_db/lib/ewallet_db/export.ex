defmodule EWalletDB.Export do
  @moduledoc """
  Ecto Schema representing audits.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import EWalletConfig.Validator
  import EWalletDB.Helpers.Preloader
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletConfig.Config

  alias EWalletDB.{
    Export,
    Repo,
    User,
    Key,
    Uploaders.File
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
    field(:completion, :float)
    field(:url, :string)
    field(:filename, :string)
    field(:path, :string)
    field(:pid, :string)
    field(:failure_reason, :string)
    field(:estimated_size, :float)
    field(:total_count, :integer)
    field(:adapter, :string)
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
        :params,
        :user_uuid,
        :key_uuid
      ],
      required: [
        :schema,
        :status,
        :completion,
        :params
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
        :url,
        :path,
        :filename,
        :adapter,
        :schema,
        :total_count,
        :estimated_size,
        :pid
      ],
      required: [
        :status,
        :completion
      ]
    )
    |> validate_inclusion(:status, [@new, @processing, @completed, @failed])
  end

  def all_for(%User{} = user) do
    from(t in Export, where: t.user_uuid == ^user.uuid)
  end

  def all_for(%Key{} = key) do
    from(t in Export, where: t.key_uuid == ^key.uuid)
  end

  @doc """
  Retrieves an export with the given ID.
  """
  @spec get(String.t(), keyword()) :: %Export{} | nil | no_return()
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an export using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %Export{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    Export
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  def init(export, schema, count, estimated_size, originator) do
    time = Timex.format!(export.inserted_at, "%Y-%m-%d_%H:%M:%S:%L", :strftime)
    filename = "#{schema}-#{export.key_uuid || export.user_uuid}-#{time}.csv"

    Export.update(export, %{
      status: Export.processing(),
      completion: 1,
      path: "#{File.storage_dir(nil, nil)}/#{filename}",
      filename: filename,
      adapter: Config.get(:file_storage_adapter),
      schema: schema,
      total_count: count,
      estimated_size: estimated_size,
      originator: originator
    })
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
