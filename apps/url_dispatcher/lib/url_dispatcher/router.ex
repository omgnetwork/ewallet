defmodule UrlDispatcher.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/api", to: ReverseProxy, upstream: ["localhost:4000"]
  forward "/admin/api", to: ReverseProxy, upstream: ["localhost:5000"]
end
