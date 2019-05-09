# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Frontend.PageControllerTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  alias Ecto.Adapters.SQL.Sandbox

  # Attributes required by Phoenix.ConnTest
  @endpoint Frontend.Endpoint

  setup do
    Sandbox.checkout(EWalletDB.Repo)
    Sandbox.checkout(ActivityLogger.Repo)
  end

  describe "GET request to /admin" do
    test "returns the main front-end app page" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/admin")
        |> html_response(:ok)

      assert response =~ "<title>OmiseGO | Loading</title>"
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

  describe "GET request to /client" do
    test "returns the main front-end app page" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/client")
        |> html_response(:ok)

      assert response =~ "<title>OmiseGO | Loading</title>"
    end

    test "returns :not_found if the index file could not be found" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../incorrect-path"))
        |> get("/client")
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

      assert response =~ "<title>OmiseGO | Loading</title>"
    end
  end

  describe "GET request to any paths below /client" do
    # This may sound counter-intuitive at first. But since we serve the Client frontend as
    # a front-end app, the backend does not have any idea whether a route exists or not.
    # So we simply serve the main front-end app page, and let front-end figure it out.
    test "returns the main app page" do
      response =
        build_conn()
        |> put_private(:override_dist_path, Path.join(__DIR__, "../test_assets/dist/"))
        |> get("/client/any-path")
        |> html_response(:ok)

      assert response =~ "<title>OmiseGO | Loading</title>"
    end
  end
end
