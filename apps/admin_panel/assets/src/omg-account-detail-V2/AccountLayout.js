import AccountNavgiationBar from './AccountNavigationBar'
import React from 'react'
import PropTypes from 'prop-types'
import { Route, withRouter } from 'react-router-dom'
import AccountWalletSubPage from './AccountWalletSubPage'
import AccountUserSubPage from './AccountUserSubPage'
import AccountTransactionSubPage from './AccountTransactionSubPage'
import AccountTransactionRequestSubPage from './AccountTransactionRequestSubPage'
import AccountDetailSubPage from './AccountDetailSubPage'
import AccountConsumptionSubPage from './AccountConsumptionSubPage'
import AccountSettingSubPage from './AccountSettingSubPage'
import AccountAdminSubPage from './AccountAdminSubPage'
import { connect } from 'react-redux'

class AccountLayout extends React.Component {
  static propTypes = {
    prop: PropTypes
  }

  render () {
    console.log('kuy')
    return (
      <div>
        <AccountNavgiationBar />
        <Route path='/accounts/:accountId/detail' exact render={() => <AccountDetailSubPage />} />
        <Route path='/accounts/:accountId/wallets' exact render={() => <AccountWalletSubPage />} />
        <Route path='/accounts/:accountId/users' exact render={() => <AccountUserSubPage />} />
        <Route path='/accounts/:accountId/admins' exact render={() => <AccountAdminSubPage />} />
        <Route path='/accounts/:accountId/setting' exact render={() => <AccountSettingSubPage />} />
        <Route
          path='/accounts/:accountId/consumptions'
          exact
          render={() => <AccountConsumptionSubPage />}
        />
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
}

AccountLayout.propTypes = {
  match: PropTypes.object
}

export default withRouter(
  connect(
    null,
    {}
  )(AccountLayout)
)
