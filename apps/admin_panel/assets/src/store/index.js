import { applyMiddleware, createStore } from 'redux'
import reducer from '../reducer'
import thunk from 'redux-thunk'
import { composeWithDevTools } from 'redux-devtools-extension'
import SocketConnector from '../../src/socket/connector'
import { WEBSOCKET_URL } from '../config'
import { handleWebsocketMessage } from '../socket/handleMessage'
import { getAccessToken, getRecentAccountFromLocalStorage } from '../services/sessionService'
import { getAccountById } from '../omg-account/action'
export function configureStore (initialState = {}, injectedThunk = {}) {
  return createStore(
    reducer,
    initialState,
    composeWithDevTools(applyMiddleware(thunk.withExtraArgument(injectedThunk)))
  )
}
const socket = new SocketConnector(WEBSOCKET_URL)
const currentUser = getAccessToken() ? getAccessToken().user : {}
const recentAccountsByUserId = getRecentAccountFromLocalStorage()

const recentAccounts = recentAccountsByUserId
  ? recentAccountsByUserId[currentUser.id].filter(d => d !== 'undefined' || !d)
  : []

// CREATE DUMMY ACCOUNT WHICH IS NOT LOADED YET INTO REDUX STORE
const accounts = recentAccounts.reduce(
  (prev, recentAccount) => ({
    ...prev,
    [recentAccount]: { id: recentAccount, injected_loading: true }
  }),
  {}
)

export const store = configureStore({ currentUser, recentAccounts, accounts }, { socket })

// PREFETCH REAL RECENT ACCOUNT
recentAccounts.forEach(accountId => {
  const getAccountAction = getAccountById(accountId)
  store.dispatch(getAccountAction)
})

socket.on('message', handleWebsocketMessage(store))
