defmodule EWalletConfig.Repo do
  use Ecto.Repo, otp_app: :ewallet_config

  # Workaround an issue where ecto.migrate task won't start the app
  # thus DeferredConfig.populate is not getting called.
  #
  # Ecto itself only supports {:system, ENV_VAR} tuple, but not
  # DeferredConfig's {:system, ENV_VAR, DEFAULT} tuple nor the
  # {:apply, MFA} tuple.
  #
  # See also: https://github.com/mrluc/deferred_config/issues/2
  def init(_, config) do
    config
    |> DeferredConfig.transform_cfg()
    |> (fn updated -> {:ok, updated} end).()
  end
end
