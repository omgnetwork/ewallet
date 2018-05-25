import React, { Component } from 'react'
import { Provider } from 'react-redux'
import store from '../store'
import { hot } from 'react-hot-loader'
import Routes from './routes'
import { ThemeProvider } from 'styled-components'
import Modal from 'react-modal'
import theme from './theme'
import 'reset-css'
import './fonts.css'
import './globalStyle.css'
import './icons.css'
Modal.setAppElement('#app')
class App extends Component {
  render () {
    return (
      <Provider store={store}>
        <ThemeProvider theme={theme}>
          <Routes />
        </ThemeProvider>
      </Provider>
    )
  }
}

export default hot(module)(App)
