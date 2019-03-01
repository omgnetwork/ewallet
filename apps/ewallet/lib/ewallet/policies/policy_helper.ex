# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.PolicyHelper do
  @moduledoc """
  The authorization policy for mints.
  """
  alias EWallet.{Bouncer, Bouncer.Permission}

  def authorize(:export, attrs, type, schema, nil) do
    authorize_scope(:export, attrs, type, schema)
  end

  def authorize(:all, attrs, type, schema, nil) do
    authorize_scope(:all, attrs, type, schema)
  end

  def authorize(action, attrs, _type, _schema, target) do
    Bouncer.bounce(attrs, %Permission{action: action, target: target})
  end

  defp authorize_scope(_action, attrs, type, schema) do
    case Bouncer.bounce(attrs, %Permission{action: :all, type: type, schema: schema}) do
      {:ok, permission} ->
        {:ok, %{permission | query: Bouncer.scoped_query(permission)}}

      error ->
        error
    end
  end
end
