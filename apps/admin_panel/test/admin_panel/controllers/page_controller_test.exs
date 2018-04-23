defmodule AdminPanel.PageControllerTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  import EWalletDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias EWalletDB.APIKey

  # Attributes required by Phoenix.ConnTest
  @endpoint AdminPanel.Endpoint

  setup do
    Sandbox.checkout(EWalletDB.Repo)
  end

  describe "GET request to /admin" do
    test "returns the main front-end app page" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/admin")
        |> html_response(:ok)

      assert response =~ "<title>Admin Panel</title>"
    end

    test "returns the main front-end app with the API key" do
      _account = insert(:account)
      {:ok, api_key} = APIKey.insert(%{owner_app: "admin_api"})

      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/admin")
        |> html_response(:ok)

      assert response =~ "<title>Admin Panel</title>"
      assert response =~ api_key.id
      assert response =~ api_key.key
    end

    test "returns the normal main front-end app if there is no API key available" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/admin")
        |> html_response(:ok)

      assert response =~ "<title>Admin Panel</title>"
      assert response =~ "<!-- No API key found -->"
      refute response =~ "var admin_api_conf"
    end

    test "returns :not_found if the index file could not be found" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../incorrect-path"))
        |> get("/admin")
        |> text_response(:not_found)

      assert response =~ "The assets are not available."
    end
  end

  describe "GET request to any paths below /admin" do
    # This may sound counter-intuitive at first. But since we serve the Admin Panel as
    # a front-end app, the backend does not have any idea whether a route exists or not.
    # So we simply serve the main front-end app page, and let front-end figure it out.
    test "returns the main app page" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/admin/any-path")
        |> html_response(:ok)

      assert response =~ "<title>Admin Panel</title>"
    end
  end
end
