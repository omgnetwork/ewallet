import React, { Component } from 'react'
import { Provider } from 'react-redux'
import { ThemeProvider } from 'styled-components'
import Modal from 'react-modal'
import PropTypes from 'prop-types'
import 'reset-css'

import theme from './theme'
import Routes from './routes'
import './fonts.css'
import './globalStyle.css'
import './icons.css'

Modal.setAppElement('#root')
class App extends Component {
  static propTypes = {
    store: PropTypes.object.isRequired
  }
  componentDidCatch () {
    return 'Something very bad happened, please contact admin.'
  }
  render () {
    return (
      <Provider store={this.props.store}>
        <ThemeProvider theme={theme}>
          <>
            <Routes />
          </>
        </ThemeProvider>
      </Provider>
    )
  }
}

export default App
