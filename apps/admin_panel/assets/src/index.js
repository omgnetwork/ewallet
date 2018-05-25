import { render } from 'react-dom'
import App from './app'
import React from 'react'

render(<App />, document.getElementById('app'))

if (module.hot) {
  module.hot.accept('./app', () => {
    render(<App />, document.getElementById('app'))
  })
}
