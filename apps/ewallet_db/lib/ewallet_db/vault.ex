defmodule EWalletDB.Vault do
  use Cloak.Vault, otp_app: :ewallet_db

  @impl Cloak.Vault
  def init(config) do
    config =
      Keyword.put(config, :ciphers, [
        default: {Salty.SecretBox.Cloak, module_tag: "SBX", tag: <<1>>, key: secret_key()}
      ])

    {:ok, config}
  end

  defp secret_key do
    if Mix.env() == :prod do
      decode_env("EWALLET_SECRET_KEY")
    else
      "j6fy7rZP9ASvf1bmywWGRjrmh8gKANrg40yWZ-rSKpI"
    end
  end

  defp decode_env(var) do
    var
    |> System.get_env(var)
    |> Base.decode64!()
  end
end
