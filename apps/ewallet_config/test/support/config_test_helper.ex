defmodule EWalletConfig.ConfigTestHelper do
  alias EWalletConfig.Config

  def restart_config_genserver(parent, repo, apps, attrs) do
    {:ok, pid} = Config.start_link()
    Ecto.Adapters.SQL.Sandbox.allow(repo, parent, pid)

    Config.insert_all_defaults(attrs, pid)

    Enum.each(apps, fn app ->
      settings = Application.get_env(app, :settings)
      Config.register_and_load(app, settings, pid)
    end)

    pid
  end
end
