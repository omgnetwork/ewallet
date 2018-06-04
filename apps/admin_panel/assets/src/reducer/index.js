import { combineReducers } from 'redux'
import appReducer from '../app/reducer'
import sessionReducer from '../omg-session/reducer'
import { accountsReducer, accountsLoadingStatusReducer } from '../omg-account/reducer'
import {
  currentAccountReducer,
  currentAccountLoadingStatusReducer
} from '../omg-account-current/reducer'
import { currentUserReducer, currentUserLoadingStatusReducer } from '../omg-user-current/reducer'
import { inviteListReducer, inviteListLoadingStatusReducer } from '../omg-invite/reducer'
import { apiKeysReducer, apiKeysLoadingStatusReducer } from '../omg-api-keys/reducer'
import { alertsReducer } from '../omg-alert/reducer'
import { tokensReducer, tokensLoadingStatusReducer } from '../omg-token/reducer'
import { usersReducer, usersLoadingStatusReducer } from '../omg-users/reducer'
import { transactionsReducer, transactionsLoadingStatusReducer } from '../omg-transaction/reducer'
import { walletsReducer, walletsLoadingStatusReducer } from '../omg-wallet/reducer'
export default combineReducers({
  app: appReducer,
  session: sessionReducer,
  accounts: accountsReducer,
  accountsLoadingStatus: accountsLoadingStatusReducer,
  currentAccount: currentAccountReducer,
  currentAccountLoadingStatus: currentAccountLoadingStatusReducer,
  currentUser: currentUserReducer,
  currentUserLoadingStatus: currentUserLoadingStatusReducer,
  inviteList: inviteListReducer,
  inviteListLoadingStatus: inviteListLoadingStatusReducer,
  apiKeys: apiKeysReducer,
  apiKeysLoadingStatus: apiKeysLoadingStatusReducer,
  alerts: alertsReducer,
  tokens: tokensReducer,
  tokensLoadingStatus: tokensLoadingStatusReducer,
  users: usersReducer,
  usersLoadingStatus: usersLoadingStatusReducer,
  transactions: transactionsReducer,
  transactionsLoadingStatus: transactionsLoadingStatusReducer,
  wallets: walletsReducer,
  walletsLoadingStatus: walletsLoadingStatusReducer
})
