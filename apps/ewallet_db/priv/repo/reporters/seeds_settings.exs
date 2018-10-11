defmodule EWalletDB.Repo.Reporters.SeedsReporter do
  alias EWalletDB.Setting

  def run(writer, _args) do
    base_url = Setting.get("base_url")
    settings = Setting.all() |> Enum.map(fn setting ->
      "- #{setting.name}: #{inspect(setting.value)}"
    end)

    writer.heading("eWallet Settings Generation")
    writer.print("""
    The following settings have been inserted:

    #{
      Enum.each(settings, fn setting ->
        setting
      end)
    }

    - -----
    - base_url: "#{base_url}"
    - redirect_url_prefixes: ["#{base_url}"]
    - enable_standalone: false
    - max_per_page: 100
    - min_password_length: 8
    - sentry_dsn: nil
    - sender_email: "admin@localhost"
    - smtp_host: nil
    - smtp_port: nil
    - smtp_username: nil
    - smtp_password: nil
    - balance_caching_strategy: "since_beginning"
    - balance_caching_schedule: "* * * * *"
    - file_storage_adapter: "local"
    - gcs_bucket: nil
    - gcs_credentials: nil
    - aws_bucket: nil
    - aws_region: nil
    - aws_access_key_id: nil
    - aws_secret_access_key: nil

    You can now update those values using the Admin API.
    """)
  end
end
