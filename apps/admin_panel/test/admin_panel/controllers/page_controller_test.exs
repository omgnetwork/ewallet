defmodule AdminPanel.PageControllerTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  # Attributes required by Phoenix.ConnTest
  @endpoint AdminPanel.Endpoint

  describe "GET request to /admin" do
    test "returns the main front-end app page" do
      response =
        build_conn()
        |> get("/admin")
        |> html_response(:ok)

      assert response =~ "<title>Admin Panel</title>"
    end
  end

  describe "GET request to any paths below /admin" do
    # This may sound counter-intuitive at first. But since we serve the Admin Panel as
    # a front-end app, the backend does not have any idea whether a route exists or not.
    # So we simply serve the main front-end app page, and let front-end figure it out.
    test "returns the main app page" do
      response =
        build_conn()
        |> get("/admin/any-path")
        |> html_response(:ok)

      assert response =~ "<title>Admin Panel</title>"
    end
  end
end
