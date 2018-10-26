# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingSeed do
  alias EWalletConfig.Config

  @argsline_desc """
  The base URL is needed for various operators in the eWallet. It will be saved in the
  settings during the seeding process and you will be able to update it later.
  """

  def seed do
    [
      run_banner: "Seeding the settings",
      argsline: get_argsline()
    ]
  end

  defp get_argsline do
    case Application.get_env(:ewallet_db, "base_url") do
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
    Config.get_default_settings()
    |> put_in(["base_url", :value], args[:base_url])
    |> put_in(["redirect_url_prefixes", :value], [args[:base_url]])
    |> Enum.each(fn data->
      run_with(writer, data)
    end)
  end

  defp run_with(writer, {key, data}) do
    case Config.get_setting(key) do
      nil ->
        case Config.insert(data) do
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
      setting ->
        writer.warn("""
          Key   : #{setting.key}
          Value : #{setting.value}
        """)
    end
  end
end
