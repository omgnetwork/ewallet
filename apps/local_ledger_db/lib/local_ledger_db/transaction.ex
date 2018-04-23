defmodule LocalLedgerDB.Transaction do
  @moduledoc """
  Ecto Schema representing transactions. A transaction is either a debit or
  credit and "moves" values around.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias LocalLedgerDB.{
    Entry,
    Repo,
    MintedToken,
    Balance,
    Transaction,
    Errors.InsufficientFundsError
  }

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  @credit "credit"
  @debit "debit"
  @types [@credit, @debit]

  def credit_type, do: @credit
  def debit_type, do: @debit

  schema "transaction" do
    field(:amount, LocalLedger.Types.Integer)
    field(:type, :string)

    belongs_to(
      :minted_token,
      MintedToken,
      foreign_key: :minted_token_id,
      references: :id,
      type: :string
    )

    belongs_to(
      :balance,
      Balance,
      foreign_key: :balance_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :entry,
      Entry,
      foreign_key: :entry_uuid,
      references: :uuid,
      type: Ecto.UUID
    )

    timestamps()
  end

  @doc """
  Validate the transaction attributes. This changeset is only used through the
  "cast_assoc" method in the Entry schema module.
  """
  def changeset(%Transaction{} = balance, attrs) do
    balance
    |> cast(attrs, [:amount, :type, :minted_token_id, :balance_address, :entry_uuid])
    |> validate_required([:amount, :type, :minted_token_id, :balance_address])
    |> validate_inclusion(:type, @types)
    |> foreign_key_constraint(:minted_token_id)
    |> foreign_key_constraint(:balance_address)
    |> foreign_key_constraint(:entry_uuid)
  end

  @doc """
  Ensure that the given address has enough funds, else raise an
  InsufficientFundsError exception.
  """
  def check_balance(
        %{amount: amount_to_debit, minted_token_id: minted_token_id, address: address} = attrs
      ) do
    current_amount = calculate_current_amount(address, minted_token_id)

    unless current_amount - amount_to_debit >= 0 do
      raise InsufficientFundsError,
        message: InsufficientFundsError.error_message(current_amount, attrs)
    end

    :ok
  end

  @doc """
  Calculate the total balances for all the specified minted tokens associated
  with the given address.
  """
  def calculate_all_balances(address, options \\ %{}) do
    options = Map.put_new(options, :minted_token_id, :all)
    credits = sum(address, Transaction.credit_type(), options)
    debits = sum(address, Transaction.debit_type(), options)

    credits |> subtract(debits) |> format()
  end

  defp subtract(credits, debits) do
    Enum.map(credits, fn {id, amount} ->
      {id, amount - (debits[id] || 0)}
    end)
  end

  defp format(balances), do: Enum.into(balances, %{})

  defp sum(address, type, options) do
    address
    |> build_sum_query(type, options)
    |> Repo.all()
    |> Enum.into(%{}, fn {k, v} -> {k, Decimal.to_integer(v)} end)
  end

  defp build_sum_query(address, type, %{minted_token_id: id, since: since, upto: upto}) do
    address
    |> build_sum_query(type, %{minted_token_id: id})
    |> where([t], t.inserted_at > ^since)
    |> where([t], t.inserted_at <= ^upto)
  end

  defp build_sum_query(address, type, %{minted_token_id: id, since: since}) do
    address
    |> build_sum_query(type, %{minted_token_id: id})
    |> where([t], t.inserted_at > ^since)
  end

  defp build_sum_query(address, type, %{minted_token_id: id, upto: upto}) do
    address
    |> build_sum_query(type, %{minted_token_id: id})
    |> where([t], t.inserted_at <= ^upto)
  end

  defp build_sum_query(address, type, %{minted_token_id: :all}) do
    Transaction
    |> where([t], t.balance_address == ^address and t.type == ^type)
    |> group_by([t], t.minted_token_id)
    |> select([t, _], {t.minted_token_id, sum(t.amount)})
  end

  defp build_sum_query(address, type, %{minted_token_id: id}) do
    address
    |> build_sum_query(type, %{minted_token_id: :all})
    |> where([t], t.minted_token_id == ^id)
  end

  @doc """
  Sum up all debit and credits for the given address/minted_token_id combo before
  substracting one from the other.
  """
  def calculate_current_amount(address, minted_token_id) do
    credit = sum_transactions_amount(address, minted_token_id, @credit) || Decimal.new(0)
    debit = sum_transactions_amount(address, minted_token_id, @debit) || Decimal.new(0)
    Decimal.to_integer(credit) - Decimal.to_integer(debit)
  end

  defp sum_transactions_amount(address, minted_token_id, type) do
    Repo.one(
      from(
        t in Transaction,
        where:
          t.balance_address == ^address and t.type == ^type and
            t.minted_token_id == ^minted_token_id,
        select: sum(t.amount)
      )
    )
  end
end
