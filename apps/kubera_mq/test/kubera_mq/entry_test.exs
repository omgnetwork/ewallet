defmodule CaishenMQ.EntryTest do
  use ExUnit.Case
  alias KuberaMQ.{Consumer, Entry}

  setup do
    {:ok, _pid} = Consumer.start_link()
    :ok
  end

  test "sends the 'v1.entry.all' operation" do
    {:ok, _pid} = Consumer.start_link()

    assert Entry.all() == {:ok, %{"operation" => "v1.entry.all"}}
  end

  test "sends the 'v1.entry.get' operation" do
    {:ok, _pid} = Consumer.start_link()

    response = Entry.get("123")

    assert response == {:ok, %{
      "operation" => "v1.entry.get",
      "data" => %{"id" => "123"}
    }}
  end

  test "sends the 'v1.entry.insert' operation" do
    {:ok, _pid} = Consumer.start_link()

    response = Entry.insert(%{})

    assert response == {:ok, %{
      "operation" => "v1.entry.insert",
      "data" => %{}
    }}
  end

  test "sends the 'v1.entry.genesis' operation" do
    {:ok, _pid} = Consumer.start_link()

    assert Entry.genesis(%{}) == {:ok, %{
      "data" => %{},
      "operation" => "v1.entry.genesis"
    }}
  end
end
