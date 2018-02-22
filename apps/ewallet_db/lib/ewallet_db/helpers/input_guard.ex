defmodule EWalletDB.Helpers.InputGuard do
  @moduledoc """
  The module that provide guard macros for input validation.
  """

  defmacro is_non_empty_string(attr) do
    quote do
      is_binary(unquote(attr)) and byte_size(unquote(attr)) > 0
    end
  end
end
