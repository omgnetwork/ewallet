defmodule CaishenMQ.EntryTest do
  use ExUnit.Case
  alias KuberaMQ.{Consumer, Entry}

  setup do
    {:ok, _pid} = Consumer.start_link()
    :ok
  end

  test "sends the 'entry.all' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.all(fn response ->
      assert response == {:ok, %{"operation" => "entry.all"}}
    end)
  end

  test "sends the 'entry.get' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.get("123", fn response ->
      assert response == {:ok, %{
          "operation" => "entry.get",
          "data" => %{"id" => "123"}
      }}
    end)
  end

  test "sends the 'entry.insert' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.insert(%{}, fn response ->
      assert response == {:ok, %{
        "operation" => "entry.insert",
        "data" => %{}
      }}
    end)
  end

  test "sends the 'entry.genesis' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.genesis(%{}, fn response ->
      assert response == {:ok, %{
        "data" => %{},
        "operation" => "entry.genesis"
      }}
    end)
  end
end
