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

defmodule EWalletDB.Repo.Reporters.SeedsReporter do
  def run(writer, _args) do

    writer.heading("Setting up test data for the OmiseGO eWallet Server")
    writer.print("""
    ```
    ###############################################################################
    #                                                                             #
    #         ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗           #
    #         ██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝           #
    #         ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗          #
    #         ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║          #
    #         ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝          #
    #         ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝            #
    #                                                                             #
    ###############################################################################
    #                                                                             #
    #  Seeded the minimum amount of data needed to run the acceptance tests.      #
    #  BE CAREFUL, admins were generated using a simple password that is          #
    #  included in the source code.                                               #
    #  These seeds should only run in a test environment.                         #
    #                                                                             #
    ###############################################################################
    ```
    """)
  end
end
