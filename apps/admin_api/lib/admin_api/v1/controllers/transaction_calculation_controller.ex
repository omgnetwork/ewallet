# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.TransactionCalculationController do
  @moduledoc """
  The controller to serve transaction calculations.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.{TokenPolicy, Exchange, Helper}
  alias EWalletDB.Token

  @doc """
  Calculates transaction amounts.
  """
  def calculate(conn, attrs) do
    with :ok <-
           check_parameters(
             attrs["from_amount"],
             attrs["from_token_id"],
             attrs["to_amount"],
             attrs["to_token_id"]
           ),
         %Token{} = from_token <- Token.get(attrs["from_token_id"]) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, from_token),
         %Token{} = to_token <- Token.get(attrs["to_token_id"]) || {:error, :unauthorized},
         {:ok, _} <- authorize(:get, conn.assigns, to_token),
         {:ok, calculation} <-
           do_calculate(attrs["from_amount"], from_token, attrs["to_amount"], to_token) do
      render(conn, :calculation, %{calculation: calculation})
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  defp check_parameters(from_amount, from_token_id, to_amount, to_token_id)

  defp check_parameters(nil, _, nil, _) do
    {:error, :invalid_parameter, "either `from_amount` or `to_amount` is required"}
  end

  defp check_parameters(_, nil, _, nil) do
    {:error, :invalid_parameter, "both `from_token_id` and `to_token_id` are required"}
  end

  defp check_parameters(_, nil, _, _) do
    {:error, :invalid_parameter, "`from_token_id` is required"}
  end

  defp check_parameters(_, _, _, nil) do
    {:error, :invalid_parameter, "`to_token_id` is required"}
  end

  defp check_parameters(_, _, _, _), do: :ok

  defp do_calculate(from_amount, from_token, to_amount, to_token) when is_binary(from_amount) do
    handle_string_amount(from_amount, fn from_amount ->
      do_calculate(from_amount, from_token, to_amount, to_token)
    end)
  end

  defp do_calculate(from_amount, from_token, to_amount, to_token) when is_binary(to_amount) do
    handle_string_amount(to_amount, fn to_amount ->
      do_calculate(from_amount, from_token, to_amount, to_token)
    end)
  end

  defp do_calculate(nil, from_token, to_amount, to_token) do
    Exchange.calculate(nil, from_token, to_amount, to_token)
  end

  defp do_calculate(from_amount, from_token, nil, to_token) do
    Exchange.calculate(from_amount, from_token, nil, to_token)
  end

  defp do_calculate(from_amount, from_token, to_amount, to_token) do
    Exchange.validate(from_amount, from_token, to_amount, to_token)
  end

  defp handle_string_amount(amount, fun) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} -> fun.(amount)
      error -> error
    end
  end

  @spec authorize(:get, map(), String.t() | nil) :: any()
  defp authorize(action, actor, token) do
    TokenPolicy.authorize(action, actor, token)
  end
end
