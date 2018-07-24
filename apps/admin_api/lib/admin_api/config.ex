defmodule AdminAPI.Config do
  @moduledoc """
  Provides a configuration function that are called during application startup.
  """

  @headers [
    "Authorization",
    "Content-Type",
    "Accept",
    "Origin",
    "User-Agent",
    "DNT",
    "Cache-Control",
    "X-Mx-ReqToken",
    "Keep-Alive",
    "X-Requested-With",
    "If-Modified-Since",
    "X-CSRF-Token",
    "OMGAdmin-Account-ID"
  ]

  def configure_cors_plug do
    max_age = System.get_env("CORS_MAX_AGE") || 600
    cors_origin = System.get_env("CORS_ORIGIN")

    Application.put_env(:cors_plug, :max_age, max_age)
    Application.put_env(:cors_plug, :headers, @headers)
    Application.put_env(:cors_plug, :methods, ["POST"])
    Application.put_env(:cors_plug, :origin, cors_plug_origin(cors_origin))
  end

  defp cors_plug_origin(nil), do: []

  defp cors_plug_origin(origins) do
    origins
    |> String.trim()
    |> String.split(~r{\s*,\s*})
  end
end
