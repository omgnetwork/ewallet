defmodule EWalletDB.Vault do
  use Cloak.Vault, otp_app: :ewallet_db

  @impl Cloak.Vault
  def init(config) do
    env = Mix.env()

    config =
      Keyword.put(
        config,
        :ciphers,
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: secret_key(env)},
        retired:
          {Salty.SecretBox.Cloak, module_tag: "SBX", tag: <<1>>, key: retired_secret_key(env)}
      )

    {:ok, config}
  end

  defp secret_key(:prod), do: decode_env("EWALLET_SECRET_KEY")

  defp secret_key(_),
    do:
      <<126, 194, 0, 33, 217, 227, 143, 82, 252, 80, 133, 89, 70, 211, 139, 150, 209, 103, 94,
        240, 194, 108, 166, 100, 48, 144, 207, 242, 93, 244, 27, 144>>

  defp retired_secret_key(:prod), do: System.get_env("RETIRED_EWALLET_SECRET_KEY")
  defp retired_secret_key(_), do: "j6fy7rZP9ASvf1bmywWGRjrmh8gKANrg40yWZ-rSKpI"

  defp decode_env(var) do
    var
    |> System.get_env()
    |> Base.decode64!()
  end
end
