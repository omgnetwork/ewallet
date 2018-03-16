defmodule EWallet.CLI do
  @moduledoc """
  Helper module for working with the command line interface.
  """

  import IO
  import IO.ANSI
  alias IO.ANSI.Docs

  def info(message), do: [:normal, message] |> format |> puts

  def debug(message), do: [:faint, message] |> format |> puts

  def success(message), do: [:green, message] |> format |> puts

  def warn(message), do: [:yellow, message] |> format |> puts

  def error(message), do: [:red, message] |> format |> puts

  def color(messages), do: messages |> format |> puts

  def heading(message), do: Docs.print_heading(message, [width: 100])

  def print(message), do: Docs.print(message, [width: 100])

  def halt(message) do
    error(message)
    System.halt(1)
  end
end
