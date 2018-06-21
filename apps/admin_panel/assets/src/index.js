import { render } from 'react-dom'
import App from './app'
import React from 'react'
import SocketConnector from '../src/socket/connector'
import { configureStore } from './store'
import createHeaders from './utils/headerGenerator'

// INITIATE WEB SOCKET WITH AUTH PARAMETERS
const socket = new SocketConnector({ header: createHeaders({ auth: true }) })
socket.connect()

// CREATE REDUX STORE WITH SOCKET INJECTED
const store = configureStore({}, { socket })

// RENDER APP
render(<App store={store} />, document.getElementById('app'))

if (module.hot) {
  module.hot.accept('./app', () => {
    render(<App />, document.getElementById('app'))
  })
  module.hot.accept('./reducer', () => {
    store.replaceReducer(require('./reducer').default)
  })
}
