# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingsSeed do
  alias EWalletDB.Seeder
  alias EWalletConfig.{Config, Setting}

  def seed do
    [
      run_banner: "Updating settings",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    {:ok, [enable_standalone: {:ok, %Setting{}}]} = Config.update(%{
      enable_standalone: true,
      originator: %Seeder{}
    })

    writer.warn("""
      Enable standalone : #{Config.get(:enable_standalone)}
    """)
  end
end
