defmodule EWallet.MintGate do
  @moduledoc """
  Handles the mint creation logic. Since it relies on external applications to
  handle the transactions (i.e. LocalLedger), a callback needs to be passed. See
  examples on how to add value to a token.
  """
  alias EWallet.{Helper, GenesisGate}
  alias EWalletDB.{Repo, Account, Mint, Token}
  alias Ecto.{UUID, Multi}

  def mint_token({:ok, token}, attrs) do
    mint_token(token, attrs)
  end

  def mint_token(token, %{"amount" => amount} = attrs)
      when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} ->
        attrs = Map.put(attrs, "amount", amount)
        mint_token(token, attrs)
      error ->
        error
    end
  end

  def mint_token(token, %{"amount" => amount} = attrs)
      when is_number(amount) do
    %{
      "idempotency_token" => attrs["idempotency_token"] || UUID.generate(),
      "token_id" => token.id,
      "amount" => amount,
      "description" => attrs["description"]
    }
    |> insert()
    |> case do
      {:ok, mint, _entry} -> {:ok, mint, token}
      {:error, code, description} -> {:error, code, description}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def mint_token({:error, changeset}, _attrs), do: {:error, changeset}
  def mint_token(_, _attrs), do: {:error, :invalid_parameter}

  @doc """
  Insert a new mint for a token, adding more value to it which can then be
  given to users.
  ## Examples
    res = MintGate.insert(%{
      "idempotency_token" => idempotency_token,
      "token_id" => token_id,
      "amount" => 100_000,
      "description" => "Another mint bites the dust.",
      "metadata" => %{probably: "something useful. Or not."},
      "encrypted_metadata" => %{something: "secret."},
    })
    case res do
      {:ok, mint, transaction} ->
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
    token = Token.get(token_id)
    account = Account.get_master_account()

    multi =
      Multi.new()
      |> Multi.run(:mint, fn _ ->
        Mint.insert(%{
          token_uuid: token.uuid,
          amount: amount,
          account_uuid: account.uuid,
          description: description
        })
      end)
      |> Multi.run(:transaction, fn _ ->
        GenesisGate.create(%{
          idempotency_token: idempotency_token,
          amount: amount,
          token: token,
          account: account,
          attrs: attrs
        })
      end)
      |> Multi.run(:mint_with_transaction, fn %{transaction: transaction, mint: mint} ->
        Mint.update(mint, %{transaction_uuid: transaction.uuid})
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        GenesisGate.process_with_transaction(result.transaction, result.mint_with_transaction)

      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end
end
