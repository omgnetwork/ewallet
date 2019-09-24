import React, { useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { Route, Switch, Redirect } from 'react-router-dom'
import { connect, useSelector, useDispatch } from 'react-redux'

import { Button } from '../omg-uikit'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
import { selectMetamaskUsable } from '../omg-web3/selector'
import {
  selectBlockchainWallets,
  selectBlockchainWalletBalance,
  selectBlockchainWalletById,
  selectPlasmaDepositByAddress
} from '../omg-blockchain-wallet/selector'
import { getAllBlockchainWallets, getBlockchainWalletBalance } from '../omg-blockchain-wallet/action'
import CreateBlockchainTransactionButton from '../omg-transaction/CreateBlockchainTransactionButton'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { getTransactionById } from '../omg-transaction/action'

import HotWalletTransferChooser from './HotWalletTransferChooser'
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
  const dispatch = useDispatch()
  const metamaskUsable = useSelector(selectMetamaskUsable)
  const balance = selectBlockchainWalletBalance(address)
    .reduce((acc, curr) => acc + curr.amount, 0)
  const walletType = selectBlockchainWalletById(address).type
  const isColdWallet = !!selectBlockchainWallets.filter(i => i.type === 'cold').length

  const [pollingState, setPollingState] = useState(false)

  useEffect(() => {
    if (!walletType) {
      getAllBlockchainWallets({
        page: 1,
        perPage: 10
      })
    }
  }, [walletType])

  useEffect(() => {
    if (pollingState) {
      const pollBalance = async () => {
        try {
          const { id: depositTransactionId } = selectPlasmaDepositByAddress(address)
          const { data: { status } } = await getTransactionById(depositTransactionId)

          if (status === 'confirmed') {
            getBlockchainWalletBalance({
              address,
              cacheKey: { address, entity: 'plasmadeposits' }
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
  }, [pollingState])

  const renderTopupButton = () => (
    <CreateBlockchainTransactionButton
      key='blockchain-transfer'
      fromAddress={address}
    />
  )

  const renderMetamaskConnectButton = () => (
    <Button
      key='create'
      size='small'
      styleType='primary'
      onClick={() => enableMetamaskEthereumConnection()(dispatch)}
      disabled={!window.ethereum || !window.web3}
    >
      <span>Enable Metamask</span>
    </Button>
  )

  const renderActionButton = () => {
    if (walletType === 'hot' && balance > 0) {
      return (
        <HotWalletTransferChooser
          key='hot-wallet-transfer'
          fromAddress={address}
          isColdWallet={isColdWallet}
          onDepositComplete={() => setPollingState(true)}
        />
      )
    }
    if (metamaskUsable) {
      return balance ? renderTopupButton() : null
    }
    return renderMetamaskConnectButton()
  }

  return (
    <>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        types={false}
        searchBar={false}
        description={address}
        buttons={[renderActionButton()]}
      />
      <Switch>
        <Route exact path={`${match.path}/tokens`} component={BlockchainTokensPage} />
        <Route exact path={`${match.path}/blockchain_transactions`} component={BlockchainTransactionsPage} />
        <Route exact path={`${match.path}/blockchain_settings`} component={BlockchainSettingsPage} />
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
