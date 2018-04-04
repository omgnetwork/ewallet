defmodule EWallet.Web.V1.ErrorHandler do
  @moduledoc """
  Handles API errors by mapping the error to its response code and description.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]
  alias Ecto.Changeset
  alias EWallet.Web.V1.{ErrorSerializer, ResponseSerializer}
  alias EWalletDB.MintedToken

  @errors %{
    invalid_version: %{
      code: "client:invalid_version",
      description: "Invalid API version",
      template: "Invalid API version. Given: {accept}."
    },
    insufficient_funds: %{
      code: "transaction:insufficient_funds",
      template: "The specified balance ({address}) does not contain enough funds. " <>
                "Available: {current_amount} {friendly_id} - Attempted debit: " <>
                "{amount_to_debit} {friendly_id}"
    }
  }

  # Used for mapping any Ecto.changeset validation
  # to make it more meaningful to send to the client.
  @validation_mapping %{
    unsafe_unique: "already_taken",
    all_or_none: "missing_dependent_params"
  }

  @doc """
  Returns a map of all the error atoms along with their code and description.
  """
  @spec errors() :: %{required(atom()) => %{code: String.t, description: String.t}}
  def errors, do: @errors

  # ---- WITH CHANGESET ----
  @doc """
  Handles response of invalid parameter error with error details provided.
  """
  @spec build_error(String.t, Ecto.Changeset.t, Map.t) :: Map.t
  def build_error(code, %Changeset{} = changeset, supported_errors) do
    description = supported_errors[code].description <> "."

    build(
      code: supported_errors[code].code,
      desc: stringify_errors(changeset, description),
      msgs: error_fields(changeset)
    )
  end

  # ---- WITH CUSTOM CODE AND DESCRIPTION ----
  @doc """
  Handles response with custom error code and description.
  """
  @spec build_error(Atom.t, String.t, Map.t) :: Map.t
  def build_error(code, description, supported_errors)
  when is_binary(description)
  when is_atom(description)
  do
    case supported_errors[code] do
      nil ->
        build(code: code, desc: description)
      error ->
        build(code: error.code, desc: description)
    end
  end

  # ---- WITH TEMPLATE DATA ----
  @doc """
  Handles response of insufficient_funds.
  """
  @spec build_error(Atom.t, Map.t, Map.t) :: Map.t
  def build_error(:insufficient_funds = code, %{
    "address" => address,
    "current_amount" => current_amount,
    "amount_to_debit" => amount_to_debit,
    "friendly_id" => friendly_id
  }, supported_errors) do
    minted_token = MintedToken.get(friendly_id)

    data = %{
      "address" => address,
      "current_amount" => float_to_binary(current_amount / minted_token.subunit_to_unit),
      "amount_to_debit" => float_to_binary(amount_to_debit / minted_token.subunit_to_unit),
      "friendly_id" => minted_token.friendly_id
    }

    build(code: code, desc: build_template(data, supported_errors[code].template))
  end

  @doc """
  Handles response with template description to build.
  """
  @spec build_error(Atom.t, Map.t, Map.t) :: Map.t
  def build_error(code, data, supported_errors) when is_map(data) do
    build(
      code: supported_errors[code].code,
      desc: build_template(data, supported_errors[code].template)
    )
  end

  # ---- WITH SUPPORTED CODE ----
  @doc """
  Handles response with default error code and description
  """
  @spec build_error(Atom.t, Map.t) :: Map.t
  def build_error(error_name, supported_errors) do
    case Map.fetch(supported_errors, error_name) do
      {:ok, error} ->
        build_error(error.code, error.description, supported_errors)
      _ ->
        build_error(:internal_server_error, error_name, supported_errors)
    end
  end

  defp build([code: code, desc: description]) do
    build([code: code, desc: description, msgs: nil])
  end
  defp build([code: code, desc: description, msgs: msgs]) do
    code
    |> ErrorSerializer.serialize(description, msgs)
    |> ResponseSerializer.serialize(success: false)
  end

  defp build_template(data, template) do
    Enum.reduce(data, template, fn({k, v}, desc) ->
      String.replace(desc, "{#{k}}", "'#{v}'")
    end)
  end

  defp stringify_errors(changeset, description) do
    Enum.reduce(changeset.errors, description, fn {field, {description, _values}}, acc ->
      acc <> " " <> stringify_field(field) <> " " <> description <> "."
    end)
  end

  defp stringify_field(fields) when is_map(fields) do
    Enum.map_join(fields, ", ", fn({key, _}) -> stringify_field(key) end)
  end
  defp stringify_field(fields) when is_list(fields) do
    Enum.map(fields, &stringify_field/1)
  end
  defp stringify_field(field) when is_atom(field) do
    "`" <> to_string(field) <> "`"
  end
  defp stringify_field({key, _}) do
    "`" <> to_string(key) <> "`"
  end

  defp float_to_binary(value) do
    :erlang.float_to_binary(value, [:compact, {:decimals, 1}])
  end

  defp error_fields(changeset) do
    traverse_errors(changeset, fn {_message, opts} ->
      validation = Keyword.get(opts, :validation)

      # Maps Ecto.changeset validation to be more meaningful
      # to send to the client.
      Map.get(@validation_mapping, validation, validation)
    end)
  end
end
