defmodule EWallet.TestEndpoint do
  @moduledoc """
  Test endpoint used to check if event broadcasts are properly received.
  """
  use Agent

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def get_events do
    Agent.get(__MODULE__, fn list -> list end)
  end

  def broadcast(topic, event, payload) do
    Agent.get_and_update(__MODULE__, fn list ->
      updated =
        list ++
          [
            %{
              topic: topic,
              event: event,
              payload: payload
            }
          ]

      {list, updated}
    end)
  end
end
