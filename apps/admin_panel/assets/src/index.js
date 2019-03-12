import { render } from 'react-dom'
import App from './app'
import React from 'react'
import { store } from './store'
import moment from 'moment'

// SETUP DEFAULT FORMAT FOR MOMENT
moment.defaultFormat = 'ddd, DD/MM/YYYY HH:mm:ss'

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
