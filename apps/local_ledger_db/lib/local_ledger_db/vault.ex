defmodule LocalLedgerDB.Vault do
  @moduledoc false

  use Cloak.Vault, otp_app: :local_ledger_db

  @impl Cloak.Vault
  def init(config) do
    env = Mix.env()

    config =
      Keyword.put(
        config,
        :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: secret_key(env)},
      )

    {:ok, config}
  end

  defp secret_key(:prod), do: decode_env("LOCAL_LEDGER_SECRET_KEY")

  defp secret_key(_),
    do:
      <<81, 98, 218, 231, 73, 11, 210, 156, 118, 252, 177, 144, 224, 97, 197, 156, 196, 13, 183,
        9, 154, 170, 231, 61, 6, 26, 166, 46, 16, 246, 150, 61>>

  defp decode_env(var) do
    var
    |> System.get_env()
    |> Base.decode64!()
  end
end
