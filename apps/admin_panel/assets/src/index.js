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
  // INIT SOCKET
  const socket = new SocketConnector(WEBSOCKET_URL)
  let store = {}

  const result = await getCurrentUser()
  if (result.data.success) {
    const currentUser = result.data.data
    const recentAccounts = getRecentAccountFromLocalStorage(currentUser.id)
    const toInjectRecentAccount = recentAccounts
      ? recentAccounts.filter(d => d !== 'undefined' || !d)
      : []
    const accounts = toInjectRecentAccount.reduce(
      (prev, recentAccount) => ({
        ...prev,
        [recentAccount]: { id: recentAccount, injected_loading: true }
      }),
      {}
    )
    store = configureStore(
      { currentUser, recentAccounts: toInjectRecentAccount, accounts },
      { socket }
    )

    // PREFETCH ACCOUNT IN RECENT TAB SIDE BAR
    toInjectRecentAccount.forEach(accountId => {
      const getAccountAction = getAccountById(accountId)
      store.dispatch(getAccountAction).then(({ type }) => {
        if (type === 'ACCOUNT/REQUEST/FAILED') {
          store.dispatch(deleteAccount(accountId))
          const removedBadRecentAccounts = getRecentAccountFromLocalStorage(currentUser.id).filter(
            id => accountId !== id
          )
          setRecentAccount(currentUser.id, removedBadRecentAccounts)
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
