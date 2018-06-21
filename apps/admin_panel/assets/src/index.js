import { render } from 'react-dom'
import App from './app'
import React from 'react'
import socket from '../src/socket/connector'
import * as sessonService from '../src/services/sessionService'
import * as headerGenerator from './utils/headerGenerator'
socket.connect({
  headers: {
    ...headerGenerator.createAuthenticationHeader({
      auth: true,
      accessToken: sessonService.getAccessToken()
    }),
    ...{ Accept: 'application/vnd.omisego.v1+json' }
  }
})
render(<App />, document.getElementById('app'))

if (module.hot) {
  module.hot.accept('./app', () => {
    render(<App />, document.getElementById('app'))
  })
}
