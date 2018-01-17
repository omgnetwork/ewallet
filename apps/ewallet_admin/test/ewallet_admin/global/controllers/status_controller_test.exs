defmodule EWalletAdmin.StatusControllerTest do
  use EWalletAdmin.ConnCase, async: true

  describe "GET request to /" do
    test "returns status ok" do

      response = build_conn()
        |> get("/")
        |> json_response(:ok)

      assert response == %{"success" => true}
    end
  end
end
