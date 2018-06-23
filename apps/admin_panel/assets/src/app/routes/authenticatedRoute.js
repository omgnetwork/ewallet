import React, { Component } from 'react'
import { Route, Redirect } from 'react-router-dom'
import AppLayout from '../../omg-app-layout'
import PropTypes from 'prop-types'
import { getAccessToken } from '../../services/sessionService'
class AuthenticatedRoute extends Component {
  static propTypes = {
    component: PropTypes.func,
    currentAccount: PropTypes.object
  }

  renderRedirectRoute = props => {
    return (
      <Redirect
        to={{
          pathname: '/login',
          state: { from: props.location === '/' ? '/dashboard' : props.location }
        }}
      />
    )
  }
  renderApp = Component => {
    return (
      <AppLayout {...this.props}>
        <Component />
      </AppLayout>
    )
  }

  render () {
    const token = getAccessToken()
    const { component: Component, ...rest } = this.props
    return (
      <Route
        {...rest}
        render={props => (token ? this.renderApp(Component) : this.renderRedirectRoute(props))}
      />
    )
  }
}
export default AuthenticatedRoute
