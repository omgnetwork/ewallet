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
const currentUser = getAccessToken().user
const recentAccounts = getRecentAccountFromLocalStorage()[currentUser.id]

export const store = configureStore({ currentUser, recentAccounts }, { socket })

// PREFETCH RECENT ACCOUNT
recentAccounts.forEach(accountId => store.dispatch(getAccountById(accountId)))

socket.on('message', handleWebsocketMessage(store))
