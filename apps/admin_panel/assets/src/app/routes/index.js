import { BrowserRouter as Router, Redirect, Switch, Route } from 'react-router-dom'
import React from 'react'

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
import AccountLayout from '../../omg-account-detail-V2/AccountLayout'
// prettier-ignore

const createRoute = () => (
  <Router basename='/admin/'>
    <Switch>
      <Redirect from='/' to={'/accounts'} exact />
      <Redirect from='/accounts/:accountId' to='/accounts/:accountId/detail' exact />
      <LoginRoute path='/login' exact component={LoginForm} />
      <LoginRoute path='/forget-password' exact component={ForgetPasswordForm} />
      <LoginRoute path='/create-new-password' exact component={CreateNewPasswordForm} />
      <LoginRoute path='/invite' exact component={InviteForm} />

      {/* MANAGE */}
      <AuthenticatedRoute path='/accounts' exact component={AccountPage} />
      <AuthenticatedRoute path='/tokens' exact component={TokenPage} />
      <AuthenticatedRoute path='/tokens/:viewTokenId/:state' exact component={TokenDetailPage} />
      <AuthenticatedRoute path='/tokens/:viewTokenId' exact component={TokenDetailPage} />
      <AuthenticatedRoute path='/wallets' exact component={WalletPage} />
      <AuthenticatedRoute path='/transaction' exact component={TransactionPage} />
      <AuthenticatedRoute path='/transaction/export' exact component={TransactionExportPage} />
      <AuthenticatedRoute path='/api' exact component={ApiKeyPage} />
      <AuthenticatedRoute path='/configuration' exact component={ConfigurationPage} />

      <AuthenticatedRoute path='/user_setting' exact component={UserSettingPage} />

      {/* SUB ACCOUNT PAGES */}
      <AuthenticatedRoute path='/accounts/:accountId/:type/:id' component={AccountLayout} />
      <AuthenticatedRoute path='/accounts/:accountId/:type' component={AccountLayout} />

      {/* OVERVIEW */}
      <AuthenticatedRoute path='/users/:userId' exact component={UserDetailPage} />
      <AuthenticatedRoute path='/consumptions' exact component={ReqestConsumptionPage} />
      <AuthenticatedRoute path='/requests' exact component={TransactionRequestPage} />
      <AuthenticatedRoute path='/activity' exact component={ActivityLogPage} />
      <AuthenticatedRoute path='/users' exact component={UserPage} />
      <AuthenticatedRoute path='/admins' exact component={AdminsPage} />
      <AuthenticatedRoute path='/admins/:adminId' exact component={AdminDetailPage} />
      <AuthenticatedRoute path='/wallets/:walletAddress' exact component={WalletDetailPage} />

      {/* 404 PAGE */}
      <AuthenticatedRoute path='/wallets/:walletAddress' exact component={WalletDetailPage} />
      <Route component={NotFoundPage} />
    </Switch>
  </Router>
)

export default createRoute
