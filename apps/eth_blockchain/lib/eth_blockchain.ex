defmodule EthBlockchain do
  @moduledoc """
  Documentation for EthBlockchain.
  """

  @typedoc """
  A tuple of `{adapter, wallet_id}` representing an identity of a adapter.
  The `wallet_id` may be `nil` to indicate a generic adapter for non-wallet
  specific operations.
  """
  @type adapter :: {atom(), String.t() | nil}

  @typedoc """
  A tuple of `{func, args}` for passing to a remote functional call
  to an adapter. In case the remote function doesn't accept any arguments,
  providing just `func` as an atom is suffice.
  """
  @type call :: {atom(), list()} | atom()
end
