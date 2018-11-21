defmodule EWalletDB.Audit do
  @moduledoc """
  Ecto Schema representing audits.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use EWalletConfig.Types.ExternalID
  import Ecto.{Changeset, Query}
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
    field(:target_encrypted_metadata, EWalletConfig.Encrypted.Map, default: %{})

    field(:originator_uuid, UUID)
    field(:originator_type, :string)

    field(:metadata, :map, default: %{})

    field(:inserted_at, :naive_datetime)
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :action,
      :target_type,
      :target_uuid,
      :target_changes,
      :target_encrypted_metadata,
      :originator_uuid,
      :originator_type,
      :metadata,
      :inserted_at
    ])
    |> validate_required([
      :action,
      :target_type,
      :target_uuid,
      :target_changes,
      :originator_uuid,
      :originator_type,
      :inserted_at
    ])
  end

  @spec get_schema(String.t()) :: Atom.t()
  def get_schema(type) do
    Application.get_env(:ewallet_db, :audit_types_to_schemas)[type]
  end

  @spec get_type(Atom.t()) :: String.t()
  def get_type(schema) do
    Application.get_env(:ewallet_db, :schemas_to_audit_types)[schema]
  end

  @spec all_for_target(Map.t()) :: [%Audit{}]
  def all_for_target(record) do
    all_for_target(record.__struct__, record.uuid)
  end

  @spec all_for_target(String.t(), UUID.t()) :: [%Audit{}]
  def all_for_target(type, uuid) when is_binary(type) do
    Audit
    |> where([a], a.target_type == ^type and a.target_uuid == ^uuid)
    |> Repo.all()
  end

  @spec all_for_target(Atom.t(), UUID.t()) :: [%Audit{}]
  def all_for_target(schema, uuid) do
    schema
    |> get_type()
    |> all_for_target(uuid)
  end

  @spec get_initial_audit(String.t(), UUID.t()) :: %Audit{}
  def get_initial_audit(type, uuid) do
    Repo.get_by(
      Audit,
      action: "insert",
      target_type: type,
      target_uuid: uuid
    )
  end

  @spec get_initial_originator(Map.t()) :: Map.t()
  def get_initial_originator(record) do
    audit_type = get_type(record.__struct__)
    audit = Audit.get_initial_audit(audit_type, record.uuid)
    originator_schema = Audit.get_schema(audit.originator_type)

    case originator_schema do
      EWalletConfig.System ->
        %EWalletConfig.System{uuid: audit.originator_uuid}

      schema ->
        Repo.get(schema, audit.originator_uuid)
    end
  end

  @spec insert_record_with_audit(%Changeset{}, Keyword.t(), Multi.t()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, :no_originator_given}
          | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
  def insert_record_with_audit(changeset, opts \\ [], multi \\ Multi.new()) do
    :insert
    |> perform(changeset, opts, multi)
    |> handle_perform_result()
  end

  @spec update_record_with_audit(%Changeset{}, Keyword.t(), Multi.t()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, :no_originator_given}
          | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
  def update_record_with_audit(changeset, opts \\ [], multi \\ Multi.new()) do
    :update
    |> perform(changeset, opts, multi)
    |> handle_perform_result()
  end

  @spec perform(Atom.t(), %Changeset{}, Keyword.t(), Multi.t()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, :no_originator_given}
          | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
  def perform(action, changeset, opts \\ [], multi \\ Multi.new()) do
    Multi
    |> apply(action, [Multi.new(), :record, changeset, opts])
    |> Multi.run(:audit, fn %{record: record} ->
      action
      |> build_attrs(changeset, record)
      |> insert_audit()
    end)
    |> Multi.append(multi)
    |> Repo.transaction()
  end

  defp handle_perform_result({:ok, %{record: record}}) do
    {:ok, record}
  end

  # Only the account insertion should fail. If the wallet insert fails, there is
  # something wrong with our code.
  defp handle_perform_result({:error, _failed_operation, changeset, _changes_so_far}) do
    {:error, changeset}
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
         changes <- Map.delete(changeset.changes, :originator),
         encrypted_metadata <- changes[:encrypted_metadata],
         changes <- Map.delete(changes, :encrypted_metadata) do
      %{
        action: Atom.to_string(action),
        target_type: target_type,
        target_uuid: record.uuid,
        target_changes: changes,
        target_encrypted_metadata: encrypted_metadata || %{},
        originator_uuid: originator.uuid,
        originator_type: originator_type,
        inserted_at: NaiveDateTime.utc_now()
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
