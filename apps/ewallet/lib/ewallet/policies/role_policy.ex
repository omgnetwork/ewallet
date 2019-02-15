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

defmodule EWallet.RolePolicy do
  @moduledoc """
  The authorization policy for roles.
  """
  alias EWallet.PolicyHelper
  alias EWallet.{Bouncer, Bouncer.Permission}

  def authorize(:all, attrs, nil) do
    Bouncer.bounce(attrs, %{action: :all, type: :roles})
  end

  def authorize(:get, attrs, role) do
    Bouncer.bounce(attrs, %{action: :get, target: role})
  end

  def authorize(:join, attrs, role) do
    Bouncer.bounce(attrs, %{action: :listen, target: role})
  end

  def authorize(:create, attrs, role) do
    Bouncer.bounce(attrs, %{action: :create, target: role})
  end

  def authorize(_, _, _), do: false
end
