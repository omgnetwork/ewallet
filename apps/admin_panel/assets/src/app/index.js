import React, { Component } from 'react'
import { Provider } from 'react-redux'
import { hot } from 'react-hot-loader/root'
import Routes from './routes'
import { ThemeProvider } from 'styled-components'
import Modal from 'react-modal'
import theme from './theme'
import PropTypes from 'prop-types'
import 'reset-css'
import './fonts.css'
import './globalStyle.css'
import './icons.css'
Modal.setAppElement('#app')
class App extends Component {
  static propTypes = {
    store: PropTypes.object.isRequired
  }
  render () {
    return (
      <Provider store={this.props.store}>
        <ThemeProvider theme={theme}>
          <Routes />
        </ThemeProvider>
      </Provider>
    )
  }
}

export default hot(App)
