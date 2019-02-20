import AccountNavgiationBar from './AccountNavigationBar'
import React from 'react'
import PropTypes from 'prop-types'
import { Route } from 'react-router-dom'
import AccountWalletSubPage from './AccountWalletSubPage'
import AccountUserSubPage from './AccountUserSubPage'
import AccountTransactionSubPage from './AccountTransactionSubPage'
import AccountTransactionRequestSubPage from './AccountTransactionRequestSubPage'
import AccountDetailSubPage from './AccountDetailSubPage'
export default function AccountLayout (props) {
  return (
    <div>
      <AccountNavgiationBar />
      <Route path='/accounts/:accountId/detail' exact render={() => <AccountDetailSubPage />} />
      <Route path='/accounts/:accountId/wallets' exact render={() => <AccountWalletSubPage />} />
      <Route path='/accounts/:accountId/users' exact render={() => <AccountUserSubPage />} />
      <Route
        path='/accounts/:accountId/transactions'
        exact
        render={() => <AccountTransactionSubPage />}
      />
      <Route
        path='/accounts/:accountId/requests'
        exact
        render={() => <AccountTransactionRequestSubPage />}
      />
    </div>
  )
}

AccountLayout.propTypes = {
  children: PropTypes.node
}
