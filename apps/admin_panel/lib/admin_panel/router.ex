defmodule AdminPanel.Router do
  use AdminPanel, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  scope "/admin", AdminPanel do
    pipe_through(:browser)
    # All requests serve from the same index page
    match(:*, "/*path", PageController, :index)
  end
end
