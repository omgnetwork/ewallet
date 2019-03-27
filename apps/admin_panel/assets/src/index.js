import { render } from 'react-dom'
import App from './app'
import React from 'react'
import moment from 'moment'
import { getCurrentUser } from './services/currentUserService'
import SocketConnector from './socket/connector'
import { WEBSOCKET_URL } from './config'
import { handleWebsocketMessage } from './socket/handleMessage'
import { getRecentAccountFromLocalStorage, setRecentAccount } from './services/sessionService'
import { getAccountById, deleteAccount } from './omg-account/action'
import { configureStore } from './store'
moment.defaultFormat = 'ddd, DD/MM/YYYY HH:mm:ss'

async function bootUp () {
  const socket = new SocketConnector(WEBSOCKET_URL)
  const result = await getCurrentUser()
  let store = {}
  if (result.data.success) {
    const currentUser = result.data.data
    const recentAccounts = getRecentAccountFromLocalStorage(currentUser.id)
      ? recentAccounts.filter(d => d !== 'undefined' || !d)
      : []
    const accounts = recentAccounts.reduce(
      (prev, recentAccount) => ({
        ...prev,
        [recentAccount]: { id: recentAccount, injected_loading: true }
      }),
      {}
    )
    store = configureStore({ currentUser, recentAccounts, accounts }, { socket })
    recentAccounts.forEach(accountId => {
      const getAccountAction = getAccountById(accountId)
      store.dispatch(getAccountAction).then(({ type, data: accountId }) => {
        if (type === 'ACCOUNT/REQUEST/FAILED') {
          const removedBadRecentAccounts = getRecentAccountFromLocalStorage(currentUser.id).filter(
            id => accountId !== id
          )
          setRecentAccount(removedBadRecentAccounts)
          store.dispatch(deleteAccount(accountId))
        }
      })
    })
  } else {
    store = configureStore({}, { socket })
  }

  socket.on('message', handleWebsocketMessage(store))
  render(<App store={store} authenticated={result.data.success} />, document.getElementById('app'))
}

// HOT RELOADING FOR DEVELOPMENT MODE
if (module.hot) {
  module.hot.accept('./app', () => {
    render(<App />, document.getElementById('app'))
  })
  module.hot.accept('./reducer', () => {
    store.replaceReducer(require('./reducer').default)
  })
}

bootUp() // BOOT UP APP :)
