defmodule Kubera.MockCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require mocking the calls to Caishen.
  """
  use ExUnit.CaseTemplate
  import Mock
  alias KuberaMQ.Entry

  using do
    quote do
      import Kubera.MockCase
    end
  end

  def mock_entry_insert_success(callback) do
    mock_entry(:insert, callback, {:ok, %{data: "from ledger"}})
  end

  def mock_entry_insert_fail(callback) do
    mock_entry(:insert, callback, {:error, "code", "description"})
  end

  def mock_entry_genesis_success(callback) do
    mock_entry(:genesis, callback, {:ok, %{data: "from ledger"}})
  end

  def mock_entry_genesis_fail(callback) do
    mock_entry(:genesis, callback, {:error, "code", "description"})
  end

  defp mock_entry(fun, callback, data) do
    with_mock Entry,
      [{fun, fn _data, _idempotency_token ->
        data
      end}] do
        callback.()
    end
  end
end
