defmodule Blockchain do
  @moduledoc """
  Documentation for Blockchain.
  """

  @typedoc """
  A tuple of `{backend, wallet_id}` representing an identity of a backend.
  The `wallet_id` may be `nil` to indicate a generic backend for non-wallet
  specific operations.
  """
  @type backend :: {atom(), String.t() | nil}

  @typedoc """
  A tuple of `{func, args}` for passing to a remote functional call
  to a backend. In case the remote function doesn't accept any arguments,
  providing just `func` as an atom is suffice.
  """
  @type call :: {atom(), list()} | atom()

  @typedoc """
  A tuple of `{backend, wallet_id, public_key}` representing a wallet
  currently managed by a backend.
  """
  @type address :: {atom(), String.t(), String.t()}
end
