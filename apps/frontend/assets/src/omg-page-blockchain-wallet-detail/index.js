import React, { useMemo } from 'react'
import PropTypes from 'prop-types'
import { Route, Switch, Redirect } from 'react-router-dom'
import { connect } from 'react-redux'

import { selectBlockchainWalletBalance } from '../omg-blockchain-wallet/selector'
import CreateBlockchainTransactionButton from '../omg-transaction/CreateBlockchainTransactionButton'
import TopNavigation from '../omg-page-layout/TopNavigation'

import BlockchainSettingsPage from './BlockchainSettingsPage'
import BlockchainTransactionsPage from './BlockchainTransactionsPage'
import BlockchainTokensPage from './BlockchainTokensPage'

const BlockchainWalletDetailPage = ({ match, selectBlockchainWalletBalance, ...rest }) => {
  const renderBlockchainTransactionButton = () => {
    return (
      <CreateBlockchainTransactionButton
        key='transfer'
        fromAddress={match.params.address}
      />
    )
  }

  const balance = useMemo(() => selectBlockchainWalletBalance(match.params.address)
    .reduce((acc, curr) => acc + curr.amount, 0), [match.params.address])

  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        types={false}
        searchBar={false}
        description={match.params.address}
        buttons={[!!balance && renderBlockchainTransactionButton()]}
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
  selectBlockchainWalletBalance: PropTypes.func
}

export default connect(
  state => ({
    selectBlockchainWalletBalance: selectBlockchainWalletBalance(state)
  })
)(BlockchainWalletDetailPage)
