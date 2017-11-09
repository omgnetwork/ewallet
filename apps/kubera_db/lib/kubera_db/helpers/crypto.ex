defmodule KuberaDB.Helpers.Crypto do
  @moduledoc """
  A helper to perform crytographic operations
  """

  @spec generate_key(integer) :: binary
  def generate_key(key_bytes) when is_integer(key_bytes) do
    key_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @spec hash_password(nil) :: nil
  def hash_password(nil), do: nil

  @spec hash_password(String.t) :: String.t
  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  @spec verify_password(String.t, String.t) :: boolean
  def verify_password(password, hash) do
    Bcrypt.verify_pass(password, hash)
  end

  @spec fake_verify :: boolean
  def fake_verify do
    Bcrypt.no_user_verify
  end
end
