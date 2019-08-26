import React from 'react'
import PropTypes from 'prop-types'
import { Route, Switch, Redirect } from 'react-router-dom'
import { connect, useSelector, useDispatch } from 'react-redux'

import { Button } from '../omg-uikit'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
import { selectMetamaskUsable } from '../omg-web3/selector'
import { selectBlockchainWalletBalance, selectBlockchainWalletById } from '../omg-blockchain-wallet/selector'
import CreateBlockchainTransactionButton from '../omg-transaction/CreateBlockchainTransactionButton'
import CreateHotWalletTransferButton from '../omg-transaction/CreateHotWalletTransferButton'
import TopNavigation from '../omg-page-layout/TopNavigation'

import BlockchainSettingsPage from './BlockchainSettingsPage'
import BlockchainTransactionsPage from './BlockchainTransactionsPage'
import BlockchainTokensPage from './BlockchainTokensPage'

const BlockchainWalletDetailPage = ({
  match,
  selectBlockchainWalletBalance,
  selectBlockchainWalletById,
  ...rest
}) => {
  const dispatch = useDispatch()
  const metamaskUsable = useSelector(selectMetamaskUsable)

  const balance = selectBlockchainWalletBalance(match.params.address)
    .reduce((acc, curr) => acc + curr.amount, 0)
  const walletType = selectBlockchainWalletById(match.params.address).type

  const renderBlockchainTransactionButton = () => (
    <CreateBlockchainTransactionButton
      key='blockchain-transfer'
      fromAddress={match.params.address}
    />
  )

  const renderHotWalletTransferButton = () => (
    <CreateHotWalletTransferButton
      key='hot-wallet-transfer'
      fromAddress={match.params.address}
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
    if (walletType === 'hot') {
      return renderHotWalletTransferButton()
    }

    if (metamaskUsable) {
      return balance ? renderBlockchainTransactionButton() : null
    }

    return renderMetamaskConnectButton()
  }

  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        types={false}
        searchBar={false}
        description={match.params.address}
        buttons={[renderActionButton()]}
      />
      <Switch>
        <Route exact path={`${match.path}/tokens`} component={BlockchainTokensPage} />
        <Route exact path={`${match.path}/blockchain_transactions`} component={BlockchainTransactionsPage} />
        <Route exact path={`${match.path}/blockchain_settings`} component={BlockchainSettingsPage} />
        <Redirect to={`${match.path}/tokens`} />
      </Switch>
    </div>
  )
}

BlockchainWalletDetailPage.propTypes = {
  match: PropTypes.object,
  selectBlockchainWalletBalance: PropTypes.func,
  selectBlockchainWalletById: PropTypes.func
}

export default connect(
  state => ({
    selectBlockchainWalletBalance: selectBlockchainWalletBalance(state),
    selectBlockchainWalletById: selectBlockchainWalletById(state)
  })
)(BlockchainWalletDetailPage)
