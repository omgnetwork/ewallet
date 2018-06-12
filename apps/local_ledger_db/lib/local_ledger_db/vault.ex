defmodule LocalLedgerDB.Vault do
  use Cloak.Vault, otp_app: :local_ledger_db

  @impl Cloak.Vault
  def init(config) do
    config =
      Keyword.put(config, :ciphers, [
        default: {Salty.SecretBox.Cloak, module_tag: "SBX", tag: <<1>>, key: secret_key(Mix.env())}
      ])

    {:ok, config}
  end

  defp secret_key(:prod), do: decode_env("LOCAL_LEDGER_SECRET_KEY")
  defp secret_key(_), do: "j6fy7rZP9ASvf1bmywWGRjrmh8gKANrg40yWZ-rSKpI"

  defp decode_env(var) do
    var
    |> System.get_env()
    |> Base.decode64!()
  end
end
