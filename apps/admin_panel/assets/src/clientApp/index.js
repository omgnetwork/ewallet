import React, { Component } from 'react'
import { BrowserRouter as Router, Switch, Route } from 'react-router-dom'
import { ThemeProvider } from 'styled-components'
import { hot } from 'react-hot-loader/root'
import 'reset-css'

import theme from '../adminPanelApp/theme'
import ResetPasswordForm from './omg-client-reset-password'
import '../adminPanelApp/globalStyle.css'

class App extends Component {
  componentDidCatch () {
    return 'Something very bad happened, please contact admin.'
  }
  render () {
    return (
      <ThemeProvider theme={theme}>
        <Router basename='/client'>
          <Switch>
            <Route path='/reset_password' exact component={ResetPasswordForm} />
          </Switch>
        </Router>
      </ThemeProvider>
    )
  }
}

export default hot(App)
