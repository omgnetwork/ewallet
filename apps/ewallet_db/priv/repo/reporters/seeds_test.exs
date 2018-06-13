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
