defmodule EWalletDB.Audit do
  @moduledoc """
  Ecto Schema representing audits.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.Changeset
  alias Ecto.{Multi, UUID}

  alias EWalletDB.{
    Audit,
    Repo
  }

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "audit" do
    external_id(prefix: "adt_")

    field(:action, :string)

    field(:target_schema, :string)
    field(:target_uuid, UUID)
    field(:target_changes, :map)

    field(:originator_uuid, UUID)
    field(:originator_schema, :string)

    field(:metadata, :map)

    field(:inserted_at, :naive_datetime)
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :action,
      :target_schema,
      :target_uuid,
      :target_changes,
      :originator_uuid,
      :originator_schema,
      :metadata
    ])
    |> validate_required([
      :action,
      :target_schema,
      :target_uuid,
      :target_changes,
      :originator_uuid,
      :originator_schema
    ])
  end

  def all_for_target(schema, uuid) do
    Audit
    |> Repo.all(target_schema: schema.audit_schema, target_uuid: uuid)
  end

  def insert(changeset, originator, multi \\ Multi.new()) do
    perform(:insert, changeset, originator, multi)
  end

  def update(changeset, originator, multi \\ Multi.new()) do
    perform(:update, changeset, originator, multi)
  end

  defp perform(action, changeset, originator, multi) do
    Multi
    |> apply(action, [Multi.new(), :record, changeset])
    |> Multi.run(:audit, fn %{record: record} ->
      action
      |> build_attrs(changeset, record, originator)
      |> insert_audit()
    end)
    |> Multi.append(multi)
    |> Repo.transaction()
  end

  defp insert_audit(attrs) do
    %Audit{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp build_attrs(action, changeset, record, originator) do
    %{
      action: Atom.to_string(action),
      target_schema: record.__struct__.audit_schema,
      target_uuid: record.uuid,
      target_changes: changeset.changes,
      originator_uuid: originator.uuid,
      originator_schema: originator.__struct__.audit_schema
    }
  end
end
