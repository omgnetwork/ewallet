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

defmodule EthBlockchain.TransactionListenerTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.TransactionListener

  describe "start_link/1"
  describe "init/1"
  describe "handle_info/:tick"
  describe "subscribe/2"
  describe "unsubscribe/2"
  describe "run/1"
end
