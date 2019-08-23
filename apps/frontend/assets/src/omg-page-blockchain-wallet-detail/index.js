import React from 'react'
import PropTypes from 'prop-types'
import { Route, Switch, Redirect } from 'react-router-dom'
import { connect } from 'react-redux'

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

  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        types={false}
        searchBar={false}
        description={match.params.address}
        buttons={balance ? [
          walletType === 'cold' && renderBlockchainTransactionButton(),
          walletType === 'hot' && renderHotWalletTransferButton()
        ] : null}
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
