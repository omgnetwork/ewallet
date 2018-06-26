import { render } from 'react-dom'
import App from './app'
import React from 'react'
import { store } from './store'

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
