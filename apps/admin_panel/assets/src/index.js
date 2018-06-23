import { render } from 'react-dom'
import App from './app'
import React from 'react'
import SocketConnector from '../src/socket/connector'
import { configureStore } from './store'
import { WEBSOCKET_URL } from './config'
import { getAccessToken } from './services/sessionService'
import createHeaders from './utils/headerGenerator'
// INITIATE WEB SOCKET
const socket = new SocketConnector(WEBSOCKET_URL)

// IF THERE IS AN AUTHENTICATION TOKEN IN LOCAL STORAGE, USE IT TO CONNECT TO WEB SOCKET
const accessToken = getAccessToken()
if (accessToken) {
  socket.setParams({ headers: createHeaders({ auth: true }) })
  socket.connect()
}
// CREATE REDUX STORE WITH SOCKET INJECTED
const store = configureStore({}, { socket })
// RENDER APP
render(<App store={store} />, document.getElementById('app'))

// HOT RELOADING FOR DEVELOPMENT MODE
if (module.hot) {
  module.hot.accept('./app', () => {
    render(<App />, document.getElementById('app'))
  })
  module.hot.accept('./reducer', () => {
    store.replaceReducer(require('./reducer').default)
  })
}
