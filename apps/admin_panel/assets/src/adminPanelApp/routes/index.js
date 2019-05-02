import React from 'react'
import { BrowserRouter as Router, Redirect, Switch, Route } from 'react-router-dom'
import PropTypes from 'prop-types'

import AuthenticatedRoute from './authenticatedRoute'
import LoginRoute from './loginRoute'
import LoginForm from '../../omg-login-form'
import ForgetPasswordForm from '../../omg-forgetPassword-form'
import CreateNewPasswordForm from '../../omg-createNewPassword-form'
import InviteForm from '../../omg-invite-form'
import AccountPage from '../../omg-page-account'
import TokenPage from '../../omg-page-token'
import TransactionPage from '../../omg-page-transaction'
import WalletPage from '../../omg-page-wallets'
import UserSettingPage from '../../omg-page-user-setting'
import ApiKeyPage from '../../omg-page-api'
import ApiKeyDetailPage from '../../omg-page-api-detail'
import UserPage from '../../omg-page-users'
import TokenDetailPage from '../../omg-page-token-detail'
import WalletDetailPage from '../../omg-page-wallet-detail'
import UserDetailPage from '../../omg-page-user-detail'
import ReqestConsumptionPage from '../../omg-page-consumption'
import TransactionRequestPage from '../../omg-page-transaction-request'
import TransactionExportPage from '../../omg-page-transaction-export'
import ConfigurationPage from '../../omg-page-configuration'
import AdminsPage from '../../omg-page-admins'
import ActivityLogPage from '../../omg-page-activity-log'
import AdminDetailPage from '../../omg-page-admin-detail'
import NotFoundPage from '../../omg-page-404'
import AccountLayout from '../../omg-page-each-account/AccountLayout'
import VerifyEmail from '../../omg-page-verify-email'
// prettier-ignore

const createRoute = ({ authenticated }) => (
  <Router basename='/admin'>
    <Switch>
      <Redirect from='/' to={'/accounts'} exact />
      <Redirect from='/accounts/:accountId' to='/accounts/:accountId/details' exact />
      <LoginRoute path='/login' exact component={LoginForm} />
      <LoginRoute path='/forget-password' exact component={ForgetPasswordForm} />
      <LoginRoute path='/create-new-password' exact component={CreateNewPasswordForm} />
      <LoginRoute path='/invite' exact component={InviteForm} />
      <Route path='/verify-email' exact component={VerifyEmail} />

      {/* MANAGE */}
      <AuthenticatedRoute authenticated={authenticated} path='/accounts' exact component={AccountPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/tokens' exact component={TokenPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/tokens/:viewTokenId/:state' exact component={TokenDetailPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/tokens/:viewTokenId' exact component={TokenDetailPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/wallets' exact component={WalletPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/transaction' exact component={TransactionPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/transaction/export' exact component={TransactionExportPage} />

      <AuthenticatedRoute authenticated={authenticated} path='/keys/:keyType/:keyDetail' exact component={ApiKeyDetailPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/keys/:keyType' exact component={ApiKeyPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/keys' exact component={ApiKeyPage} />

      <AuthenticatedRoute authenticated={authenticated} path='/configuration' exact component={ConfigurationPage} />

      <AuthenticatedRoute authenticated={authenticated} path='/user_setting' exact component={UserSettingPage} />

      {/* SUB ACCOUNT PAGES */}
      <AuthenticatedRoute authenticated={authenticated} path='/accounts/:accountId/:type/:id' component={AccountLayout} />
      <AuthenticatedRoute authenticated={authenticated} path='/accounts/:accountId/:type' component={AccountLayout} />

      {/* OVERVIEW */}
      <AuthenticatedRoute authenticated={authenticated} path='/users/:userId' exact component={() => <UserDetailPage withBreadCrumb />} />

      <AuthenticatedRoute authenticated={authenticated} path='/consumptions' exact component={ReqestConsumptionPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/requests' exact component={TransactionRequestPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/activity' exact component={ActivityLogPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/users' exact component={UserPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/admins' exact component={AdminsPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/admins/:adminId' exact component={AdminDetailPage} />
      <AuthenticatedRoute authenticated={authenticated} path='/wallets/:walletAddress' exact component={WalletDetailPage} />

      {/* 404 PAGE */}
      <AuthenticatedRoute authenticated={authenticated} path='/wallets/:walletAddress' exact component={WalletDetailPage} />
      <Route component={NotFoundPage} />
    </Switch>
  </Router>
)

createRoute.propTypes = {
  authenticated: PropTypes.bool
}
export default createRoute
