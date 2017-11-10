defmodule KuberaDB.UserTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias KuberaDB.{Repo, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "User validation" do
    test "has a valid factory" do
      changeset = User.changeset(%User{}, params_for(:user))
      assert changeset.valid?
    end

    test "prevents creation of a user without username" do
      changeset = User.changeset(%User{}, params_for(:user, %{username: nil}))
      refute changeset.valid?

      expected_errors = [
        username: {"can't be blank", [validation: :required]}
      ]

      assert changeset.errors == expected_errors
    end

    test "prevents creation of a user with an username already in DB" do
      {:ok, _} =
        :user
        |> build(%{username: "same_username"})
        |> Repo.insert

      {:error, user} =
        %User{}
        |> User.changeset(params_for(:user, %{username: "same_username"}))
        |> Repo.insert

      assert user.errors == [
        username: {"has already been taken",
        [validation: :unsafe_unique, fields: [:username]]}
      ]
    end

    test "prevents creation of a user without provider_user_id" do
      changeset = User.changeset(
        %User{},
        params_for(:user, %{provider_user_id: nil}))

      refute changeset.valid?

      expected_errors = [
        provider_user_id: {"can't be blank", [validation: :required]}
      ]

      assert changeset.errors == expected_errors
    end

    test "prevents creation of a user with an existing provider_user_id" do
      {:ok, _} =
        :user
        |> build(%{provider_user_id: "same_provider_user_id"})
        |> Repo.insert

      {:error, user} =
        %User{}
        |> User.changeset(params_for(:user, %{provider_user_id: "same_provider_user_id"}))
        |> Repo.insert

      expected_errors = [
        provider_user_id: {
          "has already been taken",
          [validation: :unsafe_unique, fields: [:provider_user_id]]
        }
      ]

      assert user.errors == expected_errors
    end

    test "prevents creation of a user without metadata" do
      changeset = User.changeset(%User{}, params_for(:user, %{metadata: nil}))
      refute changeset.valid?

      expected_errors = [
        metadata: {"can't be blank", [validation: :required]}
      ]

      assert changeset.errors == expected_errors
    end
  end

  describe "insert/1" do
    test "inserts a user if it does not exist" do
      {:ok, inserted_user} = :user |> params_for |> User.insert
      user = User.get(inserted_user.id)

      assert user.id == inserted_user.id
      assert user.username == inserted_user.username
      assert user.provider_user_id == inserted_user.provider_user_id
      assert user.metadata["first_name"] == inserted_user.metadata["first_name"]
      assert user.metadata["last_name"] == inserted_user.metadata["last_name"]
    end

    test "generates a UUID in place of a regular integer ID" do
      {res, user} = :user |> build |> Repo.insert
      uuid_pattern = ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/

      assert res == :ok
      assert String.match?(user.id, uuid_pattern)
    end

    test "generates the inserted_at and updated_at values" do
      {res, user} = :user |> build |> Repo.insert

      assert res == :ok
      assert user.inserted_at != nil
      assert user.updated_at != nil
    end

    test "automatically creates a balance when user is created" do
      {_result, user} = :user |> params_for |> User.insert
      User.get_main_balance(user)
      assert length(User.get(user.id).balances) == 1
    end
  end

  describe "update/2" do
    test "updates a user with provided attributes" do
      {res, user} =
        :user
        |> insert(%{username: "original"})
        |> User.update(%{username: "changed"})

      assert res == :ok
      assert user.username == "changed"
    end

    test "updates a user with unchanged provider_user_id" do
      {res, user} =
        :user
        |> insert(%{provider_user_id: "original", username: "original"})
        |> User.update(%{provider_user_id: "original", username: "changed"})

      assert res == :ok
      assert user.username == "changed"
    end

    test "prevents changing provider_user_id" do
      {res, changeset} =
        :user
        |> insert(%{provider_user_id: "original"})
        |> User.update(%{provider_user_id: "changed"})

      assert res == :error
      assert changeset.errors == [provider_user_id: {"can't be changed", []}]
    end
  end

  describe "get/1" do
    test "returns the existing user" do
      {_, inserted_user} =
        :user
        |> build(%{id: "06ba7634-109e-42e6-8f40-52fc5bc08a9c"})
        |> Repo.insert

      user = User.get("06ba7634-109e-42e6-8f40-52fc5bc08a9c")
      assert user.id == inserted_user.id
    end

    test "returns nil if user does not exist" do
      user = User.get("00000000-0000-0000-0000-000000000000")
      assert user == nil
    end
  end

  describe "get_by_provider_user_id/1" do
    test "returns the existing user from the provider_user_id" do
      {_, inserted_user} =
        :user
        |> build(%{provider_user_id: "1234"})
        |> Repo.insert

      user = User.get_by_provider_user_id("1234")
      assert user.provider_user_id == inserted_user.provider_user_id
    end

    test "returns nil if user does not exist" do
      user = User.get_by_provider_user_id("an_invalid_provider_id")
      assert user == nil
    end
  end

  describe "get_main_balance/1" do
    test "returns the first balance" do
      {:ok, inserted} = User.insert(params_for(:user))
      balance = User.get_main_balance(inserted)

      user =
        inserted.id
        |> User.get()
        |> Repo.preload([:balances])

      assert balance != nil
      assert balance == Enum.at(user.balances, 0)
    end

    test "make sure only 1 balance is created at most" do
      {:ok, inserted} = User.insert(params_for(:user))
      balance_1 = User.get_main_balance(inserted)
      balance_2 = User.get_main_balance(inserted)
      assert balance_1 == balance_2
    end
  end
end
