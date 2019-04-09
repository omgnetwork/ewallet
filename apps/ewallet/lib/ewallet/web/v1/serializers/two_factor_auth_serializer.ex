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

defmodule EWallet.Web.V1.TwoFactorAuthSerializer do
  @moduledoc """
  Serializes 2FA code generated into V1 JSON response format.
  """
  alias EWalletDB.{User}

  def serialize(%{secret_2fa_code: secret_2fa_code, issuer: issuer, label: label}) do
    %{
      object: "secret_code",
      secret_2fa_code: secret_2fa_code,
      issuer: issuer,
      label: label
    }
  end

  def serialize(%{backup_codes: backup_codes}) do
    %{
      object: "backup_codes",
      backup_codes: backup_codes
    }
  end
end
