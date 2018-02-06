defmodule AdminPanel.Router do
  use AdminPanel, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope "/admin", AdminPanel do
    pipe_through :browser
    match :*, "/*path", PageController, :index # All requests serve from the same index page
  end
end
