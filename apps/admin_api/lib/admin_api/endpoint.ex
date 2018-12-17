defmodule AdminAPI.Endpoint do
  use Phoenix.Endpoint, otp_app: :admin_api
  use Appsignal.Phoenix
  use Sentry.Phoenix.Endpoint

  plug(
    Plug.Static,
    at: "/public/",
    from: Path.join(File.cwd!(), "../../public/"),
    only: ~w(uploads)
  )

  plug(AdminAPI.AssetNotFoundPlug)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(CORSPlug)

  plug(AdminAPI.Router)
end
