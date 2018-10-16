defmodule EWalletConfig.EmailSettingsLoader do
  def load(app, mailer) do
    load_email_setting(app, mailer)
  end

  def load_email_setting(app, mailer) do
    settings =
      "smtp_adapter"
      |> EWalletConfig.Setting.get_value()
      |> build_email_setting()

    Application.put_env(app, mailer, settings)
  end

  defp build_email_setting("smtp") do
    %{
      adapter: Bamboo.SMTPAdapter,
      server: EWalletConfig.Setting.get_value("smtp_host"),
      port: EWalletConfig.Setting.get_value("smtp_port"),
      username: EWalletConfig.Setting.get_value("smtp_username"),
      password: EWalletConfig.Setting.get_value("smtp_password")
    }
  end

  defp build_email_setting("local") do
    %{
      adapter: Bamboo.LocalAdapter
    }
  end

  defp build_email_setting("test") do
    %{
      adapter: Bamboo.TestAdapter
    }
  end

  defp build_email_setting(_) do
    %{
      adapter: Bamboo.LocalAdapter
    }
  end
end
