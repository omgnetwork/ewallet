defmodule EWallet.MintGate do
  @moduledoc """
  Handles the mint creation logic. Since it relies on external applications to
  handle the transactions (i.e. LocalLedger), a callback needs to be passed. See
  examples on how to add value to a minted token.
  """
  alias EWallet.TransferGate
  alias EWalletDB.{Repo, Account, Mint, Wallet, Transfer, MintedToken}
  alias Ecto.Multi

  @doc """
  Insert a new mint for a token, adding more value to it which can then be
  given to users.

  ## Examples

    res = Mint.insert(%{
      "idempotency_token" => idempotency_token,
      "token_id" => minted_token_id,
      "amount" => 100_000,
      "description" => "Another mint bites the dust.",
      "metadata" => %{probably: "something useful. Or not."},
      "encrypted_metadata" => %{something: "secret."},
    })

    case res do
      {:ok, mint, ledger_response} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # insert failed.
      {:error, changeset} ->
        # Something went wrong, check the errors in the changeset!
    end

  """
  def insert(
        %{
          "idempotency_token" => idempotency_token,
          "token_id" => token_id,
          "amount" => amount,
          "description" => description
        } = attrs
      ) do
    minted_token = MintedToken.get(token_id)
    account = Account.get_master_account()

    multi =
      Multi.new()
      |> Multi.run(:mint, fn _ ->
        Mint.insert(%{
          minted_token_uuid: minted_token.uuid,
          amount: amount,
          account_uuid: account.uuid,
          description: description
        })
      end)
      |> Multi.run(:transfer, fn _ ->
        TransferGate.get_or_insert(%{
          idempotency_token: idempotency_token,
          from: Wallet.get_genesis().address,
          to: Account.get_primary_wallet(account).address,
          minted_token_id: minted_token.id,
          amount: amount,
          metadata: attrs["metadata"] || %{},
          encrypted_metadata: attrs["encrypted_metadata"] || %{},
          payload: attrs
        })
      end)
      |> Multi.run(:mint_with_transfer, fn %{transfer: transfer, mint: mint} ->
        Mint.update(mint, %{transfer_uuid: transfer.uuid})
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        process_with_transfer(result.transfer, result.mint_with_transfer)

      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  defp process_with_transfer(%Transfer{status: "pending"} = transfer, mint) do
    transfer
    |> TransferGate.genesis()
    |> confirm_and_return(mint)
  end

  defp process_with_transfer(%Transfer{status: "confirmed"} = transfer, mint) do
    confirm_and_return(transfer, mint)
  end

  defp process_with_transfer(%Transfer{status: "failed"} = transfer, mint) do
    resp = transfer.ledger_response
    confirm_and_return({:error, resp["code"], resp["description"]}, mint)
  end

  defp confirm_and_return({:error, code, description}, mint),
    do: {:error, code, description, mint}

  defp confirm_and_return(transfer, mint) do
    mint = Mint.confirm(mint)
    {:ok, mint, transfer}
  end
end
