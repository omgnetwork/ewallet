import AccountNavgiationBar from './AccountNavigationBar'
import React, { useEffect } from 'react'
import PropTypes from 'prop-types'
import { Route, withRouter, Link } from 'react-router-dom'
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
import { subscribeToWebsocketByAccountId } from '../omg-account/action'
import { visitAccount } from '../omg-recent-account/action'
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
    { subscribeToWebsocketByAccountId, visitAccount }
  )
)
function AccountLayout (props) {
  const { accountId, type, id } = props.match.params

  useEffect(() => {
    props.visitAccount(accountId)
    props.subscribeToWebsocketByAccountId(accountId)
  }, [accountId])

  return (
    <div>
      <AccountNavgiationBar />
      <BreadContainer>
        <Breadcrumb
          items={[
            <Link to={'/accounts/'}>Accounts</Link>,
            <Link to={`/accounts/${accountId}/detail`}>{_.get(props.account, 'name', '...')}</Link>,
            <Link to={`/accounts/${accountId}/${type}`}>{_.upperFirst(type)}</Link>,
            id ? <Link to={`/accounts/${accountId}/${type}/${id}`}>{id}</Link> : null
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
      <Route path='/accounts/:accountId/admins/:adminId' exact render={() => <AdminDetailPage />} />
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
      <Route path='/accounts/:accountId/activity' exact render={() => <AccountActivitySubPage />} />
    </div>
  )
}

AccountLayout.propTypes = {
  match: PropTypes.object,
  account: PropTypes.object,
  subscribeToWebsocketByAccountId: PropTypes.func
}

export default enhance(AccountLayout)
