import AccountNavgiationBar from './AccountNavigationBar'
import React, { Component } from 'react'
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
import WalletDetailPage from '../omg-page-wallet-detail'
import UserDetailPage from '../omg-page-user-detail'
import AdminDetailPage from '../omg-page-admin-detail'
import AccountActivitySubPage from './AccountActivitySubPage'
import { selectGetAccountById } from '../omg-account/selector'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { Breadcrumb } from '../omg-uikit'
import styled from 'styled-components'

const BreadContainer = styled.div`
  padding: 20px 0 0 0;
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`
const enhance = compose(
  withRouter,
  connect(
    (state, props) => {
      return { account: selectGetAccountById(state)(props.match.params.accountId) }
    },
    null
  )
)
class AccountLayout extends Component {
  render () {
    return (
      <div>
        <AccountNavgiationBar />
        <BreadContainer>
          <Breadcrumb
            items={[
              'Account',
              _.get(this.props.account, 'name', '...'),
              _.upperFirst(this.props.match.params.type),
              this.props.match.params.id
            ]}
          />
        </BreadContainer>
        <Route path='/accounts/:accountId/detail' exact render={() => <AccountDetailSubPage />} />
        <Route path='/accounts/:accountId/wallets' exact render={() => <AccountWalletSubPage />} />
        <Route
          path='/accounts/:accountId/wallets/:walletAddress'
          exact
          render={() => <WalletDetailPage />}
        />
        <Route path='/accounts/:accountId/users' exact render={() => <AccountUserSubPage />} />
        <Route path='/accounts/:accountId/users/:userId' exact render={() => <UserDetailPage />} />
        <Route path='/accounts/:accountId/admins' exact render={() => <AccountAdminSubPage />} />
        <Route
          path='/accounts/:accountId/admins/:adminId'
          exact
          render={() => <AdminDetailPage />}
        />
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
        <Route
          path='/accounts/:accountId/activity'
          exact
          render={() => <AccountActivitySubPage />}
        />
      </div>
    )
  }
}

AccountLayout.propTypes = {
  match: PropTypes.object,
  account: PropTypes.object
}

export default enhance(AccountLayout)
