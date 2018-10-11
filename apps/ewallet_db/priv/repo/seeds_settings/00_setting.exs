# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingSeed do
  alias EWalletDB.Setting

  @argsline_desc """
  The base URL is needed for various operators in the eWallet. It will be saved in the
  settings during the seeding process and you will be able to update it later.
  """

  @seed_data [
    # Global Settings
    %{key: "enable_standalone", value: false, type: "boolean"},
    %{key: "max_per_page", value: 100, type: "integer"},
    %{key: "min_password_length", value: 8, type: "integer"},
    %{key: "sentry_dsn", value: nil, type: "string"},
    %{key: "redirect_url_prefixes", value: [], type: "array"},

    # Email Settings
    %{key: "sender_email", value: "admin@localhost", type: "string"},
    %{key: "smtp_host", value: nil, type: "string"},
    %{key: "smtp_port", value: nil, type: "string"},
    %{key: "smtp_username", value: nil, type: "string"},
    %{key: "smtp_password", value: nil, type: "string"},

    # Balance Caching Settings
    %{key: "balance_caching_strategy", value: "since_beginning", type: "select", options: ["since_beginning", "since_last_cached"]},

    # File Storage settings
    %{key: "file_storage_adapter", value: "local", type: "select", options: ["local", "gcs", "aws"]},

    # File Storage: GCS Settings
    %{key: "gcs_bucket", value: nil, type: "string", parent: "file_storage_adapter", parent_value: "gcs"},
    %{key: "gcs_credentials", value: nil, secret: true, type: "string", parent: "file_storage_adapter", parent_value: "gcs"},

    # File Storage: AWS Settings
    %{key: "aws_bucket", value: nil, type: "string", parent: "file_storage_adapter", parent_value: "aws"},
    %{key: "aws_region", value: nil, type: "string", parent: "file_storage_adapter", parent_value: "aws"},
    %{key: "aws_access_key_id", value: nil, type: "string", parent: "file_storage_adapter", parent_value: "aws"},
    %{key: "aws_secret_access_key", value: nil, secret: true, type: "string", parent: "file_storage_adapter", parent_value: "aws"}
  ]

  def seed do
    [
      run_banner: "Seeding the settings",
      argsline: get_argsline()
    ]
  end

  defp get_argsline do
    case Setting.get("base_url") do
      nil ->
        [
          {:title, "Enter the base URL for this instance of the ewallet (e.g. https://myewallet.com)."},
          {:text, @argsline_desc},
          {:input, {:text, :base_url, "Base URL", System.get_env("BASE_URL") || "http://localhost:4000"}}
        ]
      _setting ->
        []
    end
  end

  def run(writer, args) do
    seed_data = [%{key: "redirect_url_prefixes", value: [args[:base_url]], type: "array"} | @seed_data]
    seed_data = [%{key: "base_url", value: args[:base_url], type: "string"} | seed_data]

    seed_data
    |> Enum.with_index(1)
    |> Enum.each(fn {data, index} ->
      run_with(writer, data, index)
    end)
  end

  defp run_with(writer, data, index) do
    case Setting.get(data.key) do
      nil ->
        data = Map.put(data, :position, index)

        case Setting.insert(data) do
          {:ok, setting} ->
            writer.success("""
              Key   : #{setting.key}
              Value : #{setting.value}
            """)
          {:error, changeset} ->
            writer.error("  The setting could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  The setting could not be inserted:")
            writer.error("  Unknown error.")
        end
      %Setting{} = setting ->
        writer.warn("""
          Key   : #{setting.key}
          Value : #{setting.value}
        """)
    end
  end
end
