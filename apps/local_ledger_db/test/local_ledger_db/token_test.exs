defmodule LocalLedgerDB.TokenTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedgerDB.Token
  alias LocalLedgerDB.Repo
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "generates a UUID" do
    {res, token} = :token |> build |> Repo.insert()

    assert res == :ok
    assert String.match?(token.uuid, ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
  end

  test "generates the inserted_at and updated_at values" do
    {res, token} = :token |> build |> Repo.insert()

    assert res == :ok
    assert token.inserted_at != nil
    assert token.updated_at != nil
  end

  test "has a valid factory" do
    changeset = Token.changeset(%Token{}, string_params_for(:token))
    assert changeset.valid?
  end

  test "prevents creation of a token without an id" do
    params = string_params_for(:token, %{id: nil})
    changeset = Token.changeset(%Token{}, params)
    refute changeset.valid?
    assert changeset.errors == [id: {"can't be blank", [validation: :required]}]
  end

  test "prevents creation of a token with an id already in DB" do
    {:ok, inserted_token} = :token |> build |> Repo.insert()

    params = string_params_for(:token, id: inserted_token.id)

    {:error, token} =
      %Token{}
      |> Token.changeset(params)
      |> Repo.insert()

    assert token.errors == [id: {"has already been taken", []}]
  end

  test "allows creation of a token with metadata" do
    {res, token} =
      :token
      |> build(%{metadata: %{e_id: "123"}})
      |> Repo.insert()

    assert res == :ok
    assert token.metadata == %{e_id: "123"}
  end

  test "saves the encrypted metadata" do
    :token
    |> build(%{metadata: %{e_id: "123"}})
    |> Repo.insert()

    {:ok, results} = SQL.query(Repo, "SELECT encrypted_metadata FROM token", [])

    row = Enum.at(results.rows, 0)
    assert <<1, 10, "AES.GCM.V1", _::binary>> = Enum.at(row, 0)
  end

  describe "#get_or_insert" do
    test "inserts the token when it does not exist yet" do
      tokens = Repo.all(Token)
      assert tokens == []

      {:ok, token} =
        Token.get_or_insert(%{
          "id" => "tok_OMG_01cbepz8h0xp9c5dvexefez2f1",
          "metadata" => %{}
        })

      tokens = Repo.all(Token)
      assert tokens == [token]
    end

    test "returns an existing token when it is already in the database" do
      {_, inserted_token} =
        :token
        |> build(%{id: "tok_BTC_01cbepxbxqg0z8nqm3eb23qec2"})
        |> Repo.insert()

      assert Enum.at(Repo.all(Token), 0).id == inserted_token.id

      {:ok, token} =
        Token.get_or_insert(%{
          "id" => "tok_BTC_01cbepxbxqg0z8nqm3eb23qec2",
          "metadata" => %{}
        })

      assert inserted_token.id == token.id
    end

    defp start_task(pid, callback) do
      {:ok, pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000
          token = callback.()
          assert token.id == "tok_OMG_01cbepz8h0xp9c5dvexefez2f1"
          send(pid, :updated)
        end)

      pid
    end

    test "handles multiple inserts happening at the same time gracefully" do
      pid = self()

      callback = fn ->
        {:ok, token} =
          Token.get_or_insert(%{
            "id" => "tok_OMG_01cbepz8h0xp9c5dvexefez2f1",
            "metadata" => %{}
          })

        token
      end

      for _ <- 0..10, do: send(start_task(pid, callback), :select_for_update)

      {:ok, token} =
        Token.get_or_insert(%{
          "id" => "tok_OMG_01cbepz8h0xp9c5dvexefez2f1",
          "metadata" => %{}
        })

      assert_receive :updated, 5000
      assert length(Repo.all(Token)) == 1
      assert token.id == "tok_OMG_01cbepz8h0xp9c5dvexefez2f1"
    end
  end

  describe "#get" do
    test "returns the existing token" do
      {_, inserted_token} =
        :token
        |> build(%{id: "tok_BTC_01cbepxbxqg0z8nqm3eb23qec2"})
        |> Repo.insert()

      token = Token.get("tok_BTC_01cbepxbxqg0z8nqm3eb23qec2")
      assert token.id == inserted_token.id
    end

    test "returns nil if token does not exist" do
      token = Token.get("tok_BTC_00000000000000000000000000")
      assert token == nil
    end
  end

  describe "#insert" do
    test "inserts a token if it does not existing" do
      assert Repo.all(Token) == []

      {:ok, token} =
        :token
        |> string_params_for
        |> Token.insert()

      assert Repo.all(Token) == [token]
    end

    test "returns the existing token without error if already existing" do
      assert Repo.all(Token) == []

      {:ok, inserted_token} =
        :token
        |> string_params_for()
        |> Token.insert()

      {res, token} =
        :token
        |> string_params_for(id: inserted_token.id)
        |> Token.insert()

      assert res == :ok
      assert inserted_token == token
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(Token) == []

      {res, changeset} =
        %{"id" => nil, "metadata" => %{}}
        |> Token.insert()

      assert res == :error
      assert changeset.errors == [id: {"can't be blank", [validation: :required]}]
    end
  end
end
