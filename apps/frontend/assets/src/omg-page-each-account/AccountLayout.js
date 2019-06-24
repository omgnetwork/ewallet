import React, { useEffect } from 'react'
import PropTypes from 'prop-types'
import { Route, withRouter, Link } from 'react-router-dom'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import styled from 'styled-components'

import UserDetailPage from '../omg-page-user-detail'
import AdminDetailPage from '../omg-page-admin-detail'
import { selectGetAccountById } from '../omg-account/selector'
import { Breadcrumb } from '../omg-uikit'
import { subscribeToWebsocketByAccountId } from '../omg-account/action'
import { visitAccount } from '../omg-recent-account/action'
import AccountNavgiationBar from './AccountNavigationBar'
import AccountWalletSubPage from './AccountWalletSubPage'
import AccountUserSubPage from './AccountUserSubPage'
import AccountTransactionSubPage from './AccountTransactionSubPage'
import AccountTransactionRequestSubPage from './AccountTransactionRequestSubPage'
import AccountDetailSubPage from './AccountDetailSubPage'
import AccountConsumptionSubPage from './AccountConsumptionSubPage'
import AccountSettingSubPage from './AccountSettingSubPage'
import AccountAdminSubPage from './AccountAdminSubPage'
import WalletDetailPage from './WalletDetailSubPage'
import AccountActivitySubPage from './AccountActivitySubPage'
import AccountKeySubPage from './AccountKeySubPage'

const BreadContainer = styled.div`
  padding: 20px 0 0 0;
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`
const enhance = compose(
  withRouter,
  connect(
    (state, props) => {
      return {
        account: selectGetAccountById(state)(props.match.params.accountId)
      }
    },
    { subscribeToWebsocketByAccountId, visitAccount }
  )
)
function AccountLayout (props) {
  const { accountId, type, id } = props.match.params
  useEffect(() => {
    if (!_.isEmpty(props.account)) {
      props.visitAccount(accountId)
      props.subscribeToWebsocketByAccountId(accountId)
    }
  }, [_.get(props, 'account.id')])

  return (
    <>
      <AccountNavgiationBar />
      <BreadContainer>
        <Breadcrumb
          items={[
            <Link key='account' to={'/accounts/'}>
              Accounts
            </Link>,
            <Link key='detail' to={`/accounts/${accountId}/details`}>
              {_.get(props.account, 'name', '...')}
            </Link>,
            <Link key='type' to={`/accounts/${accountId}/${type}`}>
              {_.upperFirst(type)}
            </Link>,
            id ? (
              <Link key='id' to={`/accounts/${accountId}/${type}/${id}`}>
                {id}
              </Link>
            ) : null
          ]}
        />
      </BreadContainer>
      <Route
        path='/accounts/:accountId/details'
        exact
        render={() => <AccountDetailSubPage />}
      />
      <Route
        path='/accounts/:accountId/wallets'
        exact
        render={() => <AccountWalletSubPage />}
      />
      <Route
        path={[
          '/accounts/:accountId/wallets/:walletAddress',
          '/accounts/:accountId/wallets/:walletAddress/:type'
        ]}
        exact
        render={() => <WalletDetailPage />}
      />
      <Route
        path='/accounts/:accountId/keys'
        exact
        render={() => <AccountKeySubPage />}
      />

      <Route
        path='/accounts/:accountId/users'
        exact
        render={() => <AccountUserSubPage />}
      />
      <Route
        path='/accounts/:accountId/users/:userId/:type'
        exact
        render={() => <UserDetailPage divider={false} />}
      />
      <Route
        path='/accounts/:accountId/users/:userId'
        exact
        render={() => <UserDetailPage divider={false} />}
      />
      <Route
        path='/accounts/:accountId/admins'
        exact
        render={() => <AccountAdminSubPage />}
      />
      <Route
        path='/accounts/:accountId/admins/:adminId'
        exact
        render={() => <AdminDetailPage divider={false} />}
      />
      <Route
        path='/accounts/:accountId/setting'
        exact
        render={() => <AccountSettingSubPage />}
      />
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
    </>
  )
}

AccountLayout.propTypes = {
  match: PropTypes.object,
  account: PropTypes.object,
  subscribeToWebsocketByAccountId: PropTypes.func,
  visitAccount: PropTypes.func
}

export default enhance(AccountLayout)
