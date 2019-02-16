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

defmodule LoadTester.Runner do
  @moduledoc """
  Defines the running sequence for the scenarios.
  """
  use Chaperon.LoadTest

  alias LoadTester.Scenarios.{
    AccountAll,
    AccountCreate,
    AccountGetWallets,
    AdminLogin,
    Index,
    TokenAll,
    TokenCreate,
    TransactionCreate,
    UserGetWallets
  }

  @concurrency 1
  @sequence [
    Index,
    AdminLogin,
    UserGetWallets,
    TokenAll,
    TokenCreate,
    AccountAll,
    AccountCreate,
    AccountGetWallets,
    TransactionCreate
  ]

  def default_config,
    do: %{
      base_url:
        Application.get_env(:load_tester, :protocol) <>
          "://" <>
          Application.get_env(:load_tester, :host) <>
          ":" <> Application.get_env(:load_tester, :port)
    }

  def scenarios,
    do: [
      {{@concurrency, @sequence}, %{}}
    ]
end
