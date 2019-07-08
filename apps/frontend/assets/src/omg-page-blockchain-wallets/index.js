import React from 'react'
import PropTypes from 'prop-types'
import { Route, Switch } from 'react-router-dom'

import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import TopNavigation from '../omg-page-layout/TopNavigation'

import BlockchainSettingsPage from './BlockchainSettingsPage'
import BlockchainTransactionsPage from './BlockchainTransactionsPage'
import BlockchainTokensPage from './BlockchainTokensPage'
import InternalTokensPage from './InternalTokensPage'

const BlockchainWalletPage = ({ match }) => {
  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        description='These are all blockchain wallets associated to you. Click each one to view their details.'
        types={false}
        searchBar={false}
        buttons={[<CreateTransactionButton key='transfer' />]}
      />
      <Switch>
        <Route exact path={`${match.path}/blockchain_tokens`} component={BlockchainTokensPage} />
        <Route exact path={`${match.path}/internal_tokens`}component={InternalTokensPage} />
        <Route exact path={`${match.path}/blockchain_transactions`} component={BlockchainTransactionsPage} />
        <Route exact path={`${match.path}/blockchain_settings`} component={BlockchainSettingsPage} />
      </Switch>
    </div>
  )
}

BlockchainWalletPage.propTypes = {
  match: PropTypes.object
}

export default BlockchainWalletPage
