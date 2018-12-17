defmodule ActivityLogger do
  @moduledoc """
  Documentation for ActivityLogger.
  """

  def configure(schemas_to_activity_log_types) do
    update_config(:schemas_to_activity_log_types, schemas_to_activity_log_types)

    update_config(
      :activity_log_types_to_schemas,
      to_activity_log_types(schemas_to_activity_log_types)
    )
  end

  defp to_activity_log_types(schemas_to_activity_log_types) do
    Enum.into(schemas_to_activity_log_types, %{}, fn {key, value} ->
      {value, key}
    end)
  end

  defp update_config(name, config) do
    current = Application.get_env(:activity_logger, name, %{})
    Application.put_env(:activity_logger, name, Map.merge(current, config))
  end
end
