defmodule EWalletDB.Audit do
  @moduledoc """
  Ecto Schema representing audits.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.Changeset
  alias Ecto.{Changeset, Multi, UUID}

  alias EWalletDB.{
    Audit,
    Repo
  }

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "audit" do
    external_id(prefix: "adt_")

    field(:action, :string)

    field(:target_type, :string)
    field(:target_uuid, UUID)
    field(:target_changes, :map)

    field(:originator_uuid, UUID)
    field(:originator_type, :string)

    field(:metadata, :map)

    field(:inserted_at, :naive_datetime)
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :action,
      :target_type,
      :target_uuid,
      :target_changes,
      :originator_uuid,
      :originator_type,
      :metadata
    ])
    |> validate_required([
      :action,
      :target_type,
      :target_uuid,
      :target_changes,
      :originator_uuid,
      :originator_type
    ])
  end

  def get_schema(type) do
    Application.get_env(:ewallet_db, :audit_types_to_schemas)[type]
  end

  def get_type(schema) do
    Application.get_env(:ewallet_db, :schemas_to_audit_types)[schema]
  end

  def all_for_target(schema, uuid) do
    Repo.all(Audit, target_type: get_type(schema), target_uuid: uuid)
  end

  def get_initial_audit(type, uuid) do
    Repo.get_by(
      Audit,
      action: "insert",
      target_type: type,
      target_uuid: uuid
    )
  end

  def get_initial_originator(audit_type, record) do
    audit = Audit.get_initial_audit(audit_type, record.uuid)
    schema = Audit.get_schema(audit.originator_type)
    struct(schema, uuid: audit.originator_uuid)
  end

  def insert(changeset, multi \\ Multi.new()) do
    perform(:insert, changeset, multi)
  end

  def update(changeset, multi \\ Multi.new()) do
    perform(:update, changeset, multi)
  end

  defp perform(action, changeset, multi) do
    Multi
    |> apply(action, [Multi.new(), :record, changeset])
    |> Multi.run(:audit, fn %{record: record} ->
      action
      |> build_attrs(changeset, record)
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

  defp build_attrs(action, changeset, record) do
    with {:ok, originator} <- get_originator(changeset, record),
         originator_type <- get_type(originator.__struct__),
         target_type <- get_type(record.__struct__),
         changes <- Map.delete(changeset.changes, :originator)
    do
      %{
        action: Atom.to_string(action),
        target_type: target_type,
        target_uuid: record.uuid,
        target_changes: changes,
        originator_uuid: originator.uuid,
        originator_type: originator_type
      }
    else
      error -> error
    end
  end

  defp get_originator(%Changeset{changes: %{originator: :self}}, record) do
    {:ok, record}
  end

  defp get_originator(%Changeset{changes: %{originator: originator}}, _) do
    {:ok, originator}
  end

  defp get_originator(_, _) do
    {:error, :no_originator_given}
  end
end
