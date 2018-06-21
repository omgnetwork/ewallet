import { render } from 'react-dom'
import App from './app'
import React from 'react'
import socket from '../src/socket/connector'
import createHeaders from './utils/headerGenerator'
socket.connect({
  headers: createHeaders({ auth: true })
})
render(<App />, document.getElementById('app'))

if (module.hot) {
  module.hot.accept('./app', () => {
    render(<App />, document.getElementById('app'))
  })
}
