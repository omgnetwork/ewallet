# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingsSeed do
  alias EWalletConfig.Config

  def seed do
    [
      run_banner: "Updating settings",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Config.update(%{
      enable_standalone: true
    })

    writer.warn("""
      Settings updated.
      Enable standalone is now: #{Config.get(:enable_standalone)}
    """)
  end
end
