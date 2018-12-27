defmodule ActivityLogger do
  @moduledoc """
  Documentation for ActivityLogger.
  """

  def configure(schemas_to_activity_log_config) do
    update_config(:schemas_to_activity_log_config, schemas_to_activity_log_config)

    update_config(
      :activity_log_types_to_schemas,
      to_activity_log_types(schemas_to_activity_log_config)
    )
  end

  defp to_activity_log_types(schemas_to_activity_log_config) do
    Enum.into(schemas_to_activity_log_config, %{}, fn {key, value} ->
      {value[:type], key}
    end)
  end

  defp update_config(name, config) do
    current = Application.get_env(:activity_logger, name, %{})
    Application.put_env(:activity_logger, name, Map.merge(current, config))
  end
end
