defmodule EWalletConfig.ConfigTestHelper do
  alias EWalletConfig.Config

  def restart_config_genserver(apps, attrs) do
    :ok = Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
    {:ok, _} = Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

    Config.insert_all_defaults(attrs)

    Enum.each(apps, fn app ->
      settings = Application.get_env(app, :settings)
      Config.register_and_load(app, settings)
    end)

  end
end
