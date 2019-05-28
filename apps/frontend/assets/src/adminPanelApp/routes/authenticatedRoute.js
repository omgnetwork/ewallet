import React, { Component } from 'react'
import { Route, Redirect } from 'react-router-dom'
import AppLayout from '../../omg-app-layout'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { bootstrap } from '../action'
import { selectSession } from '../../omg-session/selector'
class AuthenticatedRoute extends Component {
  static propTypes = {
    component: PropTypes.oneOfType([PropTypes.func, PropTypes.object]),
    currentAccount: PropTypes.object,
    bootstrap: PropTypes.func,
    authenticated: PropTypes.bool
  }
  componentDidMount = async () => {
    this.props.bootstrap()
  }
  renderRedirectRoute = props => {
    return (
      <Redirect
        to={{
          pathname: '/login',
          state: { from: props.location === '/' ? '/accounts' : props.location }
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
  renderPage = (props, Component) => {
    if (!this.props.authenticated) {
      return this.renderRedirectRoute(props)
    }
    return this.renderApp(Component)
  }

  render () {
    const { component: Component, ...rest } = this.props
    return <Route {...rest} render={props => this.renderPage(props, Component)} />
  }
}
export default connect(
  state => ({ authenticated: selectSession(state).authenticated }),
  { bootstrap }
)(AuthenticatedRoute)
