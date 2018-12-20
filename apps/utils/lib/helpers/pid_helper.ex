defmodule Utils.Helper.PidHelper do
  @moduledoc """
  Module helping out with PID <> String conversions.
  """

  def pid_to_binary(pid) when is_pid(pid) do
    "#PID" <> (pid |> :erlang.pid_to_list() |> :erlang.list_to_binary())
  end

  def pid_to_binary(port) when is_port(port) do
    port |> :erlang.port_to_list() |> :erlang.list_to_binary()
  end

  # the msg tracer seems to give us back the registered name
  def pid_to_binary(atom) when is_atom(atom) do
    atom |> :erlang.whereis() |> pid_to_binary
  end

  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end

  def pid_from_string(string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_atom()
    |> :erlang.whereis()
  end
end
