defmodule LocalLedgerDB.BalanceTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedgerDB.Balance
  alias LocalLedgerDB.Repo
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "initialization" do
    test "generates a UUID in place of a regular ID" do
      {res, balance} = :balance |> build |> Repo.insert

      assert res == :ok
      assert String.match?(balance.id,
                           ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, balance} = :balance |> build |> Repo.insert

      assert res == :ok
      assert balance.inserted_at != nil
      assert balance.updated_at != nil
    end

    test "saves the encrypted metadata" do
      :balance |> build(%{metadata: %{e_id: "123"}}) |> Repo.insert

      {:ok, results} = SQL.query(Repo, "SELECT * FROM balance", [])

      row = Enum.at(results.rows, 0)
      assert <<"SBX", 1, _::binary>> = Enum.at(row, 2)
    end
  end

  describe "validations" do
    test "has a valid factory" do
      changeset = Balance.changeset(%Balance{},
                                    string_params_for(:balance))
      assert changeset.valid?
    end

    test "prevents creation of a balance without an address" do
      params = string_params_for(:balance, %{address: nil})
      changeset = Balance.changeset(%Balance{}, params)
      refute changeset.valid?
      assert changeset.errors == [address: {"can't be blank",
                                            [validation: :required]}]
    end

    test "prevents creation of a balance with an address already in DB" do
      {:ok, _} = :balance |> build |> Repo.insert

      {:error, balance} = %Balance{}
                          |> Balance.changeset(string_params_for(:balance))
                          |> Repo.insert

      assert balance.errors == [address: {"has already been taken", []}]
    end

    test "allows creation of a balance with metadata" do
      {res, balance} = :balance
                       |> build(%{metadata: %{e_id: "123"}})
                       |> Repo.insert

      assert res == :ok
      assert balance.metadata == %{e_id: "123"}
    end
  end

  describe "#touch" do
    test "touches the balance" do
      {_, inserted_balance} = :balance
                              |> build
                              |> Repo.insert

      Balance.touch([inserted_balance.address])
      updated_balance = Balance.get(inserted_balance.address)
      assert updated_balance.updated_at != inserted_balance.updated_at
    end
  end

  describe "#get_or_insert" do
    test "inserts the balance when it does not exist yet" do
      balances = Repo.all(Balance)
      assert balances == []

      {:ok, balance} = Balance.get_or_insert(%{
        "address" => "123",
        "metadata" => %{}
      })

      balances = Repo.all(Balance)
      assert balances == [balance]
    end

    test "returns an existing balance when it is already in the database" do
      {_, inserted_balance} = :balance
                              |> build(%{address: "456"})
                              |> Repo.insert

      assert Enum.at(Repo.all(Balance), 0).id == inserted_balance.id
      {:ok, balance} = Balance.get_or_insert(%{
        "address" => "456",
        "metadata" => %{}
      })
      assert inserted_balance.id == balance.id
    end

    defp start_task(pid, callback) do
      {:ok, pid} = Task.start_link fn ->
        Sandbox.allow(Repo, pid, self())
        assert_receive :select_for_update, 5000
        balance = callback.()
        assert balance.address == "123"
        send pid, :updated
      end

      pid
    end

    test "handles multiple inserts happening at the same time gracefully" do
      pid = self()

      callback = fn ->
        {:ok, balance} = Balance.get_or_insert(%{
          "address" => "123",
          "metadata" => %{}
        })
        balance
      end

      for _ <- 0..10, do: send(start_task(pid, callback), :select_for_update)

      {:ok, balance} = Balance.get_or_insert(%{
        "address" => "123",
        "metadata" => %{}
      })

      assert_receive :updated, 5000
      assert length(Repo.all(Balance)) == 1
      assert balance.address == "123"
    end
  end

  describe "#get" do
    test "returns the existing balance" do
      {_, inserted_balance} = :balance
                              |> build(%{address: "456"})
                              |> Repo.insert
      balance = Balance.get("456")
      assert balance.id == inserted_balance.id
    end

    test "returns nil if balance does not exist" do
      balance = Balance.get("456")
      assert balance == nil
    end
  end

  describe "#insert" do
    test "inserts a balance if it does not existing" do
      assert Repo.all(Balance) == []
      {:ok, balance} = :balance |> string_params_for |> Balance.insert
      assert Repo.all(Balance) == [balance]
    end

    test "returns the existing balance without error if already existing" do
      assert Repo.all(Balance) == []
      inserted_balance = :balance |> string_params_for |> Balance.insert
      balance = :balance |> string_params_for |> Balance.insert

      assert inserted_balance == balance
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(Balance) == []
      {res, changeset} = %{"address" => nil, "metadata" => %{}}
                         |> Balance.insert
      assert res == :error
      assert changeset.errors == [address: {"can't be blank",
                                            [validation: :required]}]
    end
  end

  describe "#lock" do
    test "locks the balances associated with the given addresses get locked" do
      {_, balance_1} = :balance |> build(%{address: "123"}) |> Repo.insert
      {_, balance_2} = :balance |> build(%{address: "345"}) |> Repo.insert
      pid = self()

      {:ok, new_pid} =
        Task.start_link fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000

          Repo.transaction(fn ->
            # this should block until the other transaction commit
            balance = Balance.get(balance_1.address)
            changeset = Balance.changeset(balance,
                                          %{metadata: %{desc: "Blocked"}})
            Repo.update!(changeset)
          end)

        send pid, :updated
      end

      {:ok, updated_balance} = Repo.transaction fn ->
        Balance.lock([balance_1.address, balance_2.address])
        send new_pid, :select_for_update

        balance_1.address
        |> Balance.get
        |> Balance.changeset(%{metadata: %{desc: "Free"}})
        |> Repo.update!

        Balance.get(balance_1.address)
      end

      assert updated_balance.metadata == %{"desc" => "Free"}
      assert_receive :updated, 5000
      assert Balance.get(balance_1.address).metadata == %{"desc" => "Blocked"}
    end
  end
end
