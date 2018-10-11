defmodule EWalletDB.Repo.Reporters.SeedsSettingsReporter do
  alias EWalletDB.Setting

  def run(writer, _args) do
    writer.heading("eWallet Settings")
    writer.print("""
    Here is your current list of settings and their values:

    """)

    Enum.each(Setting.all(), fn setting ->
      writer.print("""
        #{setting.position}. #{setting.key} (#{setting.type}): #{inspect_value(setting)}
      """)
    end)

    writer.print("""

    You can update those values using the Admin API.
    """)
  end

  defp inspect_value(%{value: nil, type: _}), do: "nil"
  defp inspect_value(%{value: value, type: "array"}), do: ~s([#{Enum.join(value, ", ")}])
  defp inspect_value(%{value: value, type: "map"}), do: inspect(value)
  defp inspect_value(%{value: value, type: "string"}), do: ~s("#{value}")
  defp inspect_value(%{value: value, type: "select"}), do: ~s("#{value}")
  defp inspect_value(%{value: value, type: "boolean"}), do: value
  defp inspect_value(%{value: value, type: "integer"}), do: value
end
