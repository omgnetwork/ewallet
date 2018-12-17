defmodule ActivityLogger.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: ActivityLogger.Repo
  alias ExMachina.Strategy

  alias ActivityLogger.{
    System,
    ActivityLog,
    TestDocument,
    TestUser
  }

  @doc """
  Get factory name (as atom) from schema.

  The function should explicitly handle schemas that produce incorrect factory name,
  e.g. when APIKey becomes :a_p_i_key
  """
  def get_factory(APIKey), do: :api_key

  def get_factory(schema) when is_atom(schema) do
    schema
    |> struct
    |> Strategy.name_from_struct()
  end

  def activity_log_factory do
    system = %System{}

    %ActivityLog{
      action: "insert",
      target_type: ActivityLog.get_type(system.__struct__),
      target_uuid: system.uuid,
      target_changes: %{some: "change"},
      originator_uuid: system.uuid,
      originator_type: ActivityLog.get_type(system.__struct__)
    }
  end

  def test_document_factory do
    %TestDocument{
      title: "My Document",
      body: "Some content",
      secret_data: %{some: "secret"},
      originator: %System{}
    }
  end

  def test_user_factory do
    %TestUser{
      username: "John",
      originator: %System{}
    }
  end
end
