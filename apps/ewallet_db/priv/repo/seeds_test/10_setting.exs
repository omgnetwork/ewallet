# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingsSeed do
  alias EWalletConfig.{Config, Setting}

  def seed do
    [
      run_banner: "Updating settings",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    {:ok, _} = Config.update(%{
      enable_standalone: true
    })

    writer.warn("""
      Enable standalone : #{Config.get(:enable_standalone)}
    """)
  end
end
