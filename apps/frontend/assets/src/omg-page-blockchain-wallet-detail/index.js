import React, { useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { Route, Switch, Redirect } from 'react-router-dom'
import { connect } from 'react-redux'

import {
  selectBlockchainWallets,
  selectBlockchainWalletBalance,
  selectBlockchainWalletById,
  selectPlasmaDepositByAddress
} from '../omg-blockchain-wallet/selector'
import {
  getAllBlockchainWallets,
  getBlockchainWalletBalance
} from '../omg-blockchain-wallet/action'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { getTransactionById } from '../omg-transaction/action'

import BlockchainActionSelector from './BlockchainActionSelector'
import BlockchainSettingsPage from './BlockchainSettingsPage'
import BlockchainTransactionsPage from './BlockchainTransactionsPage'
import BlockchainTokensPage from './BlockchainTokensPage'

const BlockchainWalletDetailPage = ({
  match,
  selectBlockchainWalletBalance,
  selectBlockchainWalletById,
  selectPlasmaDepositByAddress,
  getAllBlockchainWallets,
  getBlockchainWalletBalance,
  getTransactionById,
  selectBlockchainWallets,
  ...rest
}) => {
  const { address } = match.params

  const balance = selectBlockchainWalletBalance(address).reduce(
    (acc, curr) => acc + curr.amount,
    0
  )
  const walletType = selectBlockchainWalletById(address).type

  const [pollingState, setPollingState] = useState(false)

  useEffect(() => {
    if (!walletType) {
      getAllBlockchainWallets({
        page: 1,
        perPage: 10
      })
    }
  }, [getAllBlockchainWallets, walletType])

  useEffect(() => {
    if (pollingState) {
      const pollBalance = async () => {
        try {
          const { id: depositTransactionId } = selectPlasmaDepositByAddress(
            address
          )
          const {
            data: { status }
          } = await getTransactionById(depositTransactionId)

          if (status === 'confirmed') {
            getBlockchainWalletBalance({
              address: address,
              cacheKey: { address: address, entity: 'plasmadeposits' }
            })
            clearInterval(balancePolling)
            setPollingState(false)
          } else {
            // keep polling until confirmed
          }
        } catch (e) {
          clearInterval(balancePolling)
          setPollingState(false)
        }
      }
      const balancePolling = setInterval(pollBalance, 2000)
      return () => clearInterval(balancePolling)
    }
  }, [
    address,
    getBlockchainWalletBalance,
    getTransactionById,
    pollingState,
    selectPlasmaDepositByAddress
  ])

  const renderActionButtons = () => {
    const ethereumActions = [
      {
        name: 'Transfer to Cold Wallet',
        modal: { id: 'hotWalletTransferModal' },
        icon: 'Transaction'
      }
    ]

    const plasmaActions = [
      {
        name: 'Deposit to the OMG Network',
        modal: {
          id: 'plasmaDepositModal',
          args: { onDepositComplete: () => setPollingState(true) }
        },
        icon: 'Download'
      }
    ]

    if (walletType === 'hot' && balance > 0) {
      return (
        <>
          <BlockchainActionSelector
            name="OMG Network"
            fromAddress={address}
            actions={plasmaActions}
          />
          <BlockchainActionSelector
            name="Ethereum"
            fromAddress={address}
            actions={ethereumActions}
          />
        </>
      )
    }
  }

  return (
    <>
      <TopNavigation
        divider
        title="Blockchain Wallet"
        types={false}
        searchBar={false}
        description={address}
        buttons={[renderActionButtons()]}
      />
      <Switch>
        <Route
          exact
          path={`${match.path}/tokens`}
          component={BlockchainTokensPage}
        />
        <Route
          exact
          path={`${match.path}/blockchain_transactions`}
          component={BlockchainTransactionsPage}
        />
        <Route
          exact
          path={`${match.path}/blockchain_settings`}
          component={BlockchainSettingsPage}
        />
        <Redirect to={`${match.path}/tokens`} />
      </Switch>
    </>
  )
}

BlockchainWalletDetailPage.propTypes = {
  match: PropTypes.object,
  selectBlockchainWalletBalance: PropTypes.func,
  selectBlockchainWalletById: PropTypes.func,
  selectBlockchainWallets: PropTypes.array,
  selectPlasmaDepositByAddress: PropTypes.func,
  getAllBlockchainWallets: PropTypes.func,
  getBlockchainWalletBalance: PropTypes.func,
  getTransactionById: PropTypes.func
}

export default connect(
  state => ({
    selectBlockchainWalletBalance: selectBlockchainWalletBalance(state),
    selectBlockchainWalletById: selectBlockchainWalletById(state),
    selectBlockchainWallets: selectBlockchainWallets(state),
    selectPlasmaDepositByAddress: selectPlasmaDepositByAddress(state)
  }),
  { getAllBlockchainWallets, getBlockchainWalletBalance, getTransactionById }
)(BlockchainWalletDetailPage)
