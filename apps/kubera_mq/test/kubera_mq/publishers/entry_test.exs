defmodule CaishenMQ.Publishers.EntryTest do
  use ExUnit.Case
  alias KuberaMQ.Publishers.Entry

  test "sends the 'v1.entry.all' operation" do
    assert Entry.all() == {:ok, %{"operation" => "v1.entry.all"}}
  end

  test "sends the 'v1.entry.get' operation" do
    response = Entry.get("123")

    assert response == {:ok, %{
      "operation" => "v1.entry.get",
      "data" => %{"id" => "123"}
    }}
  end

  test "sends the 'v1.entry.insert' operation" do
    response = Entry.insert(%{}, "123")

    assert response == {:ok, %{
      "operation" => "v1.entry.insert",
      "idempotency_token" => "123",
      "data" => %{}
    }}
  end

  test "sends the 'v1.entry.genesis' operation" do
    assert Entry.genesis(%{}, "123") == {:ok, %{
      "data" => %{},
      "operation" => "v1.entry.genesis",
      "idempotency_token" => "123",
    }}
  end
end
