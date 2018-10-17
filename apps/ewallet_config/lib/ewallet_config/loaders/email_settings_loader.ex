defmodule EWalletConfig.EmailSettingsLoader do
  alias EWalletConfig.Setting

  def load(app, mailer) do
    load_email_setting(app, mailer)
  end

  def load_email_setting(app, mailer) do
    settings =
      "smtp_adapter"
      |> Setting.get()
      |> build_email_setting()

    Application.put_env(app, mailer, settings)
  end

  defp build_email_setting("smtp") do
    %{
      adapter: Bamboo.SMTPAdapter,
      server: Setting.get("smtp_host"),
      port: Setting.get("smtp_port"),
      username: Setting.get("smtp_username"),
      password: Setting.get("smtp_password")
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
