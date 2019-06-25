import { render } from 'react-dom'

import React from 'react'
import moment from 'moment'
import { getCurrentUser } from './services/currentUserService'
import SocketConnector from './socket/connector'
import { WEBSOCKET_URL } from './config'
import { handleWebsocketMessage } from './socket/handleMessage'
import {
  getRecentAccountFromLocalStorage,
  setRecentAccount
} from './services/sessionService'
import { getAccountById, deleteAccount } from './omg-account/action'
import { configureStore } from './store'
import tokenExpireMiddleware from './adminPanelApp/middlewares/tokenExpireMiddleware'
moment.defaultFormat = 'ddd, DD/MM/YYYY HH:mm:ss'

// ===================================== ADMIN APP =====================================
async function bootAdminPanelApp () {
  // INIT SOCKET
  const socket = new SocketConnector(WEBSOCKET_URL)
  let store = {}

  const {
    data: { success, data: currentUserData }
  } = await getCurrentUser()

  if (success) {
    const currentUser = currentUserData
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
      {
        currentUser,
        recentAccounts: toInjectRecentAccount,
        accounts,
        session: { authenticated: true }
      },
      { socket },
      [tokenExpireMiddleware]
    )

    // PREFETCH ACCOUNT IN RECENT TAB SIDE BAR
    toInjectRecentAccount.forEach(accountId => {
      const getAccountAction = getAccountById(accountId)
      store.dispatch(getAccountAction).then(({ type }) => {
        if (type === 'ACCOUNT/REQUEST/FAILED') {
          store.dispatch(deleteAccount(accountId))
          const removedBadRecentAccounts = getRecentAccountFromLocalStorage(
            currentUser.id
          ).filter(id => accountId !== id)
          setRecentAccount(currentUser.id, removedBadRecentAccounts)
        }
      })
    })
  } else {
    store = configureStore({ session: { authenticated: false } }, { socket }, [
      tokenExpireMiddleware
    ])
  }

  // HANDLE WEBSOCKET MESSAGES
  socket.on('message', handleWebsocketMessage(store))

  const App = await import('./adminPanelApp')
  const LoadedApp = App.default
  if (!LoadedApp) return false
  render(
    <LoadedApp store={store} authenticated={success} />,
    document.getElementById('app')
  )
  // HOT RELOADING FOR DEVELOPMENT MODE
  if (module.hot) {
    module.hot.accept('./adminPanelApp', () => {
      render(<LoadedApp />, document.getElementById('app'))
    })
    module.hot.accept('./reducer', () => {
      store.replaceReducer(require('./reducer').default)
    })
  }
  console.log('Started Admin panel app.')
  return true
}

// ===================================== CLIENT APP =====================================

async function bootClientApp () {
  const App = await import('./clientApp')
  const LoadedApp = App.default
  if (!LoadedApp) return false
  render(<LoadedApp />, document.getElementById('app'))
  // HOT RELOADING FOR DEVELOPMENT MODE
  if (module.hot) {
    module.hot.accept('./clientApp', () => {
      render(<LoadedApp />, document.getElementById('app'))
    })
  }
  console.log('Started client app.')
  return true
}

// ===================================== BOOT APP =====================================

async function bootApp () {
  const [, app] = window.location.pathname.split('/')
  console.log(`Starting up ${app} app...`)
  switch (app) {
    case 'admin':
      return bootAdminPanelApp()
    case 'client':
      return bootClientApp()
    default:
      return false
  }
}

bootApp()
