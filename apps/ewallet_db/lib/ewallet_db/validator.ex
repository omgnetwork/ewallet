defmodule EWalletDB.Validator do
  @moduledoc """
  Custom validators that extend Ecto.Changeset's list of built-in validators.
  """
  alias Ecto.Changeset
  alias EWalletDB.Wallet

  def validate_from_wallet_identifier(changeset) do
    from = Changeset.get_field(changeset, :from)
    wallet = Wallet.get(from)

    case Wallet.burn_wallet?(wallet) do
      true ->
        Changeset.add_error(
          changeset,
          :from,
          "can't be the address of a burn wallet",
          validation: :burn_wallet_as_sender_not_allowed
        )

      false ->
        changeset
    end
  end
end
