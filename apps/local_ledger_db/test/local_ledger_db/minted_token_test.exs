defmodule LocalLedgerDB.MintedTokenTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedgerDB.MintedToken
  alias LocalLedgerDB.Repo
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "generates a UUID" do
    {res, minted_token} = :minted_token |> build |> Repo.insert()

    assert res == :ok
    assert String.match?(minted_token.uuid, ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
  end

  test "generates the inserted_at and updated_at values" do
    {res, minted_token} = :minted_token |> build |> Repo.insert()

    assert res == :ok
    assert minted_token.inserted_at != nil
    assert minted_token.updated_at != nil
  end

  test "has a valid factory" do
    changeset = MintedToken.changeset(%MintedToken{}, string_params_for(:minted_token))
    assert changeset.valid?
  end

  test "prevents creation of a minted_token without an id" do
    params = string_params_for(:minted_token, %{id: nil})
    changeset = MintedToken.changeset(%MintedToken{}, params)
    refute changeset.valid?
    assert changeset.errors == [id: {"can't be blank", [validation: :required]}]
  end

  test "prevents creation of a minted_token with an id already in DB" do
    {:ok, _} = :minted_token |> build |> Repo.insert()

    params = string_params_for(:minted_token)

    {:error, minted_token} =
      %MintedToken{}
      |> MintedToken.changeset(params)
      |> Repo.insert()

    assert minted_token.errors == [id: {"has already been taken", []}]
  end

  test "allows creation of a minted_token with metadata" do
    {res, minted_token} =
      :minted_token
      |> build(%{metadata: %{e_id: "123"}})
      |> Repo.insert()

    assert res == :ok
    assert minted_token.metadata == %{e_id: "123"}
  end

  test "saves the encrypted metadata" do
    :minted_token
    |> build(%{metadata: %{e_id: "123"}})
    |> Repo.insert()

    {:ok, results} = SQL.query(Repo, "SELECT encrypted_metadata FROM minted_token", [])

    row = Enum.at(results.rows, 0)
    assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)
  end

  describe "#get_or_insert" do
    test "inserts the minted_token when it does not exist yet" do
      minted_tokens = Repo.all(MintedToken)
      assert minted_tokens == []

      {:ok, minted_token} =
        MintedToken.get_or_insert(%{
          "id" => "tok_OMG_01cbepz8h0xp9c5dvexefez2f1",
          "metadata" => %{}
        })

      minted_tokens = Repo.all(MintedToken)
      assert minted_tokens == [minted_token]
    end

    test "returns an existing minted_token when it is already in the database" do
      {_, inserted_minted_token} =
        :minted_token
        |> build(%{id: "tok_BTC_01cbepxbxqg0z8nqm3eb23qec2"})
        |> Repo.insert()

      assert Enum.at(Repo.all(MintedToken), 0).id == inserted_minted_token.id

      {:ok, minted_token} =
        MintedToken.get_or_insert(%{
          "id" => "tok_BTC_01cbepxbxqg0z8nqm3eb23qec2",
          "metadata" => %{}
        })

      assert inserted_minted_token.id == minted_token.id
    end

    defp start_task(pid, callback) do
      {:ok, pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000
          minted_token = callback.()
          assert minted_token.id == "tok_OMG_01cbepz8h0xp9c5dvexefez2f1"
          send(pid, :updated)
        end)

      pid
    end

    test "handles multiple inserts happening at the same time gracefully" do
      pid = self()

      callback = fn ->
        {:ok, minted_token} =
          MintedToken.get_or_insert(%{
            "id" => "tok_OMG_01cbepz8h0xp9c5dvexefez2f1",
            "metadata" => %{}
          })

        minted_token
      end

      for _ <- 0..10, do: send(start_task(pid, callback), :select_for_update)

      {:ok, minted_token} =
        MintedToken.get_or_insert(%{
          "id" => "tok_OMG_01cbepz8h0xp9c5dvexefez2f1",
          "metadata" => %{}
        })

      assert_receive :updated, 5000
      assert length(Repo.all(MintedToken)) == 1
      assert minted_token.id == "tok_OMG_01cbepz8h0xp9c5dvexefez2f1"
    end
  end

  describe "#get" do
    test "returns the existing minted_token" do
      {_, inserted_minted_token} =
        :minted_token
        |> build(%{id: "tok_BTC_01cbepxbxqg0z8nqm3eb23qec2"})
        |> Repo.insert()

      minted_token = MintedToken.get("tok_BTC_01cbepxbxqg0z8nqm3eb23qec2")
      assert minted_token.id == inserted_minted_token.id
    end

    test "returns nil if minted_token does not exist" do
      minted_token = MintedToken.get("tok_BTC_00000000000000000000000000")
      assert minted_token == nil
    end
  end

  describe "#insert" do
    test "inserts a minted_token if it does not existing" do
      assert Repo.all(MintedToken) == []

      {:ok, minted_token} =
        :minted_token
        |> string_params_for
        |> MintedToken.insert()

      assert Repo.all(MintedToken) == [minted_token]
    end

    test "returns the existing token without error if already existing" do
      assert Repo.all(MintedToken) == []

      inserted_minted_token =
        :minted_token
        |> string_params_for
        |> MintedToken.insert()

      minted_token = :minted_token |> string_params_for |> MintedToken.insert()

      assert inserted_minted_token == minted_token
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(MintedToken) == []

      {res, changeset} =
        %{"id" => nil, "metadata" => %{}}
        |> MintedToken.insert()

      assert res == :error
      assert changeset.errors == [id: {"can't be blank", [validation: :required]}]
    end
  end
end
