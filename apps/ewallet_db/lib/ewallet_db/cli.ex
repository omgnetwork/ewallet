defmodule EWalletDB.CLI do
  @moduledoc """
  Helper module for working with the command line interface.
  """

  import IO
  import IO.ANSI

  def info(message),
    do: [:normal, message] |> format |> puts

  def success(message),
    do: [:green, message] |> format |> puts

  def warn(message),
    do: [:yellow, message] |> format |> puts

  def error(message),
    do: [:red, message] |> format |> puts

  def halt(message) do
    error(message)
    System.halt(1)
  end
end
