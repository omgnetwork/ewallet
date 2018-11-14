defmodule EWalletConfig.Helpers.InputAttribute do
  @moduledoc """
  Helper functions to deal with input attributes.
  """

  @doc """
  Get an input attribute by name.

  The name and the input key can be agnostically either an atom or string.
  """
  @spec get(map(), atom() | String.t()) :: any()
  def get(attrs, attr_name) when is_atom(attr_name) do
    Map.get(attrs, attr_name) || Map.get(attrs, to_string(attr_name))
  end

  def get(attrs, attr_name) when is_binary(attr_name) do
    Map.get(attrs, attr_name) || Map.get(attrs, String.to_existing_atom(attr_name))
  end
end
