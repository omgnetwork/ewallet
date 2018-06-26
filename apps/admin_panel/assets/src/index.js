import { render } from 'react-dom'
import App from './app'
import React from 'react'
import SocketConnector from '../src/socket/connector'
import { configureStore } from './store'
import { WEBSOCKET_URL } from './config'
// INITIATE WEB SOCKET
const socket = new SocketConnector(WEBSOCKET_URL)
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
