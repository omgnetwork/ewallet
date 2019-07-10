import React from 'react'
import PropTypes from 'prop-types'
import { Route, Switch, Redirect } from 'react-router-dom'

import CreateBlockchainTransactionButton from '../omg-transaction/CreateBlockchainTransactionButton'
import TopNavigation from '../omg-page-layout/TopNavigation'

import BlockchainSettingsPage from './BlockchainSettingsPage'
import BlockchainTransactionsPage from './BlockchainTransactionsPage'
import BlockchainTokensPage from './BlockchainTokensPage'
import InternalTokensPage from './InternalTokensPage'

const BlockchainWalletDetailPage = ({ match, ...rest }) => {
  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        types={false}
        searchBar={false}
        description={match.params.address}
        buttons={[
          <CreateBlockchainTransactionButton
            key='transfer'
            fromAddress={match.params.address}
          />
        ]}
      />
      <Switch>
        <Route exact path={`${match.path}/blockchain_tokens`} component={BlockchainTokensPage} />
        <Route exact path={`${match.path}/internal_tokens`}component={InternalTokensPage} />
        <Route exact path={`${match.path}/blockchain_transactions`} component={BlockchainTransactionsPage} />
        <Route exact path={`${match.path}/blockchain_settings`} component={BlockchainSettingsPage} />
        <Redirect to={`${match.path}/blockchain_tokens`} />
      </Switch>
    </div>
  )
}

BlockchainWalletDetailPage.propTypes = {
  match: PropTypes.object
}

export default BlockchainWalletDetailPage
