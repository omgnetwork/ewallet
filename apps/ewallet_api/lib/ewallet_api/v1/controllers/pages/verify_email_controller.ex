# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.VerifyEmailController do
  @moduledoc """
  Handles pages for email verification.
  """
  use EWalletAPI, :controller
  import EWalletAPI.V1.PageRouter.Helpers, only: [verify_email_path: 2]
  alias EWallet.SignupGate
  alias EWallet.Web.V1.ErrorHandler

  def verify_url, do: build_url("/pages/client/v1/verify_email?email={email}&token={token}")

  def success_url, do: build_url("/pages/client/v1/verify_email/success")

  defp build_url(path) do
    Application.get_env(:ewallet_api, :base_url) <> path
  end

  @doc """
  Renders the landing page to start the email verification steps.
  """
  def verify(conn, attrs) do
    case SignupGate.verify_email(attrs) do
      {:ok, %{success_url: nil}} ->
        redirect(conn, to: verify_email_path(conn, :success))

      {:ok, %{success_url: success_url}} ->
        redirect(conn, external: success_url)

      {:error, error} ->
        case Map.get(ErrorHandler.errors(), error) do
          %{description: description} ->
            text(conn, "We were unable to verify your email address. " <> description)

          nil ->
            text(conn, "We were unable to verify your email address. An unknown error occured.")
        end
    end
  end

  @doc """
  Renders the page to show when email verification is successful.
  """
  def success(conn, _attrs) do
    text(conn, "Your email address has been successfully verified!")
  end
end
