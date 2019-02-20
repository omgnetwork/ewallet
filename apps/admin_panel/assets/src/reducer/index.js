import { combineReducers } from 'redux'
import appReducer from '../app/reducer'
import sessionReducer from '../omg-session/reducer'
import { accountsReducer } from '../omg-account/reducer'
import { currentUserReducer } from '../omg-user-current/reducer'
import { inviteListReducer } from '../omg-member/reducer'
import { apiKeysReducer } from '../omg-api-keys/reducer'
import { accessKeysReducer } from '../omg-access-key/reducer'
import { alertsReducer } from '../omg-alert/reducer'
import { tokensReducer, mintedTokenHistoryReducer } from '../omg-token/reducer'
import { usersReducer } from '../omg-users/reducer'
import { consumptionsReducer } from '../omg-consumption/reducer'
import { transactionsReducer } from '../omg-transaction/reducer'
import { transactionRequestsReducer } from '../omg-transaction-request/reducer'
import { walletsReducer } from '../omg-wallet/reducer'
import { categoriesReducer } from '../omg-account-category/reducer'
import { loadingBarReducer } from 'react-redux-loading-bar'
import { cacheReducer } from '../omg-cache/reducer'
import { exchangePairsReducer } from '../omg-exchange-pair/reducer'
import { configurationReducer } from '../omg-configuration/reducer'
import { activitiesReducer } from '../omg-activity-log/reducer'
import { loadingStatusReducer } from '../omg-loading-status/reducer'
import { exportsReducer } from '../omg-export/reducer'
import { adminsReducer } from '../omg-admins/reducer'
export default combineReducers({
  app: appReducer,
  admins: adminsReducer,
  loadingBar: loadingBarReducer,
  session: sessionReducer,
  accounts: accountsReducer,
  accessKeys: accessKeysReducer,
  consumptions: consumptionsReducer,
  currentUser: currentUserReducer,
  inviteList: inviteListReducer,
  apiKeys: apiKeysReducer,
  alerts: alertsReducer,
  tokens: tokensReducer,
  transactionRequests: transactionRequestsReducer,
  users: usersReducer,
  transactions: transactionsReducer,
  wallets: walletsReducer,
  categories: categoriesReducer,
  exchangePairs: exchangePairsReducer,
  cacheQueries: cacheReducer,
  mintedTokenHistory: mintedTokenHistoryReducer,
  configurations: configurationReducer,
  activities: activitiesReducer,
  exports: exportsReducer,
  loadingStatus: loadingStatusReducer
})
