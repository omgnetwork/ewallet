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
      assert response == %{
        "status" => "ok",
        "payload" => %{
          "operation" => "entry.all"
        }
      }
    end)
  end

  test "sends the 'entry.get' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.get("123", fn response ->
      assert response == %{
        "status" => "ok",
        "payload" => %{
          "operation" => "entry.get",
          "data" => %{"id" => "123"}
        }
      }
    end)
  end

  test "sends the 'entry.insert' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.insert(%{}, fn response ->
      assert response == %{
        "payload" => %{
          "operation" => "entry.insert",
          "data" => %{}
        },
        "status" => "ok"
      }
    end)
  end

  test "sends the 'entry.genesis' operation" do
    {:ok, _pid} = Consumer.start_link()

    Entry.genesis(%{}, fn response ->
      assert response == %{
        "payload" => %{
          "data" => %{},
          "operation" => "entry.genesis"
        },
        "status" => "ok"
      }
    end)
  end
end
