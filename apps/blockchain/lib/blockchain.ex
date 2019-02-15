defmodule Blockchain do
  @moduledoc """
  Documentation for Blockchain.
  """

  @type backend :: {atom(), String.t() | nil}
  @type call :: {atom(), arity()} | atom()

  @type address :: {atom(), String.t(), String.t()}
end
