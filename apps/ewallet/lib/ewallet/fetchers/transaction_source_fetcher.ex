defmodule EWallet.TransactionSourceFetcher do
  @moduledoc """
  Handles the logic for fetching the token and the from and to wallets.
  """
  alias EWallet.WalletFetcher
  alias EWalletDB.{Repo, Account, User}

  def fetch_from(%{"from_account_id" => from_account_id, "from_user_id" => from_user_id})
      when not is_nil(from_account_id) and not is_nil(from_user_id) do
    {:error, :invalid_parameter, "'from_account_id' and 'from_user_id' are exclusive"}
  end

  def fetch_from(%{
        "from_account_id" => from_account_id,
        "from_provider_user_id" => from_provider_user_id
      })
      when not is_nil(from_account_id) and not is_nil(from_provider_user_id) do
    {:error, :invalid_parameter, "'from_account_id' and 'from_provider_user_id' are exclusive"}
  end

  def fetch_from(%{
        "from_user_id" => from_user_id,
        "from_provider_user_id" => from_provider_user_id
      })
      when not is_nil(from_user_id) and not is_nil(from_provider_user_id) do
    {:error, :invalid_parameter, "'from_user_id' and 'from_provider_user_id' are exclusive"}
  end

  def fetch_from(%{"from_account_id" => from_account_id, "from_address" => from_address})
      when not is_nil(from_account_id) do
    with %Account{} = account <- Account.get(from_account_id) || {:error, :account_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(account, from_address),
         true <- wallet.enabled || {:error, :from_wallet_is_disabled} do
      {:ok,
       %{
         from_account_uuid: account.uuid,
         from_wallet_address: wallet.address
       }}
    else
      {:error, :account_wallet_not_found} ->
        {:error, :from_address_not_found}

      {:error, :account_wallet_mismatch} ->
        {:error, :account_from_address_mismatch}

      error ->
        error
    end
  end

  def fetch_from(%{"from_user_id" => from_user_id, "from_address" => from_address})
      when not is_nil(from_user_id) do
    with %User{} = user <- User.get(from_user_id) || {:error, :user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, from_address),
         true <- wallet.enabled || {:error, :from_wallet_is_disabled}  do
      {:ok,
       %{
         from_user_uuid: user.uuid,
         from_wallet_address: wallet.address
       }}
    else
      {:error, :user_wallet_not_found} ->
        {:error, :from_address_not_found}

      {:error, :user_wallet_mismatch} ->
        {:error, :user_from_address_mismatch}

      error ->
        error
    end
  end

  def fetch_from(%{
        "from_provider_user_id" => from_provider_user_id,
        "from_address" => from_address
      })
      when not is_nil(from_provider_user_id) do
    with %User{} = user <-
           User.get_by_provider_user_id(from_provider_user_id) ||
             {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, from_address),
         true <- wallet.enabled || {:error, :from_wallet_is_disabled}  do
      {:ok,
       %{
         from_user_uuid: user.uuid,
         from_wallet_address: wallet.address
       }}
    else
      {:error, :user_wallet_not_found} ->
        {:error, :from_address_not_found}

      {:error, :user_wallet_mismatch} ->
        {:error, :user_from_address_mismatch}

      error ->
        error
    end
  end

  def fetch_from(%{"from_address" => from_address}) when not is_nil(from_address) do
    with {:ok, wallet} <- WalletFetcher.get(nil, from_address),
         wallet <- Repo.preload(wallet, [:account, :user]),
         true <- wallet.enabled || {:error, :from_wallet_is_disabled}  do
      case is_nil(wallet.account_uuid) do
        true ->
          {:ok,
           %{
             from_user_uuid: wallet.user.uuid,
             from_wallet_address: wallet.address
           }}

        false ->
          {:ok,
           %{
             from_account_uuid: wallet.account.uuid,
             from_wallet_address: wallet.address
           }}
      end
    else
      {:error, :wallet_not_found} ->
        {:error, :from_address_not_found}

      error ->
        error
    end
  end

  def fetch_from(%{"from_account_id" => from_account_id}) when not is_nil(from_account_id) do
    fetch_from(%{"from_account_id" => from_account_id, "from_address" => nil})
  end

  def fetch_from(%{"from_user_id" => from_user_id}) when not is_nil(from_user_id) do
    fetch_from(%{"from_user_id" => from_user_id, "from_address" => nil})
  end

  def fetch_from(%{"from_provider_user_id" => from_provider_user_id})
      when not is_nil(from_provider_user_id) do
    fetch_from(%{"from_provider_user_id" => from_provider_user_id, "from_address" => nil})
  end

  def fetch_from(_) do
    {:error, :invalid_parameter}
  end

  def fetch_to(%{"to_account_id" => to_account_id, "to_user_id" => to_user_id})
      when not is_nil(to_account_id) and not is_nil(to_user_id) do
    {:error, :invalid_parameter, "'to_account_id' and 'to_user_id' are exclusive"}
  end

  def fetch_to(%{"to_account_id" => to_account_id, "to_provider_user_id" => to_provider_user_id})
      when not is_nil(to_account_id) and not is_nil(to_provider_user_id) do
    {:error, :invalid_parameter, "'to_account_id' and 'to_provider_user_id' are exclusive"}
  end

  def fetch_to(%{"to_user_id" => to_user_id, "to_provider_user_id" => to_provider_user_id})
      when not is_nil(to_user_id) and not is_nil(to_provider_user_id) do
    {:error, :invalid_parameter, "'to_user_id' and 'to_provider_user_id' are exclusive"}
  end

  def fetch_to(%{"to_account_id" => to_account_id, "to_address" => to_address})
      when not is_nil(to_account_id) do
    with %Account{} = account <- Account.get(to_account_id) || {:error, :account_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(account, to_address),
         true <- wallet.enabled || {:error, :to_wallet_is_disabled}  do
      {:ok,
       %{
         to_account_uuid: account.uuid,
         to_wallet_address: wallet.address
       }}
    else
      {:error, :account_wallet_not_found} ->
        {:error, :to_address_not_found}

      {:error, :account_wallet_mismatch} ->
        {:error, :account_to_address_mismatch}

      error ->
        error
    end
  end

  def fetch_to(%{"to_user_id" => to_user_id, "to_address" => to_address})
      when not is_nil(to_user_id) do
    with %User{} = user <- User.get(to_user_id) || {:error, :user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, to_address),
         true <- wallet.enabled || {:error, :to_wallet_is_disabled} do
      {:ok,
       %{
         to_user_uuid: user.uuid,
         to_wallet_address: wallet.address
       }}
    else
      {:error, :user_wallet_not_found} ->
        {:error, :to_address_not_found}

      {:error, :user_wallet_mismatch} ->
        {:error, :user_to_address_mismatch}

      error ->
        error
    end
  end

  def fetch_to(%{"to_provider_user_id" => to_provider_user_id, "to_address" => to_address})
      when not is_nil(to_provider_user_id) do
    with %User{} = user <-
           User.get_by_provider_user_id(to_provider_user_id) ||
             {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, to_address),
         true <- wallet.enabled || {:error, :to_wallet_is_disabled} do
      {:ok,
       %{
         to_user_uuid: user.uuid,
         to_wallet_address: wallet.address
       }}
    else
      {:error, :user_wallet_not_found} ->
        {:error, :to_address_not_found}

      {:error, :user_wallet_mismatch} ->
        {:error, :user_to_address_mismatch}

      error ->
        error
    end
  end

  def fetch_to(%{"to_address" => to_address}) when not is_nil(to_address) do
    with {:ok, wallet} <- WalletFetcher.get(nil, to_address),
         wallet <- Repo.preload(wallet, [:account, :user]),
         true <- wallet.enabled || {:error, :to_wallet_is_disabled} do
      case is_nil(wallet.account_uuid) do
        true ->
          {:ok,
           %{
             to_user_uuid: wallet.user.uuid,
             to_wallet_address: wallet.address
           }}

        false ->
          {:ok,
           %{
             to_account_uuid: wallet.account.uuid,
             to_wallet_address: wallet.address
           }}
      end
    else
      {:error, :wallet_not_found} ->
        {:error, :to_address_not_found}

      error ->
        error
    end
  end

  def fetch_to(%{"to_account_id" => to_account_id}) when not is_nil(to_account_id) do
    fetch_to(%{"to_account_id" => to_account_id, "to_address" => nil})
  end

  def fetch_to(%{"to_user_id" => to_user_id}) when not is_nil(to_user_id) do
    fetch_to(%{"to_user_id" => to_user_id, "to_address" => nil})
  end

  def fetch_to(%{"to_provider_user_id" => to_provider_user_id})
      when not is_nil(to_provider_user_id) do
    fetch_to(%{"to_provider_user_id" => to_provider_user_id, "to_address" => nil})
  end

  def fetch_to(_) do
    {:error, :invalid_parameter}
  end
end
