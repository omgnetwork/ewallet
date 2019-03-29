import React, { Component } from 'react'
import { Route, Redirect } from 'react-router-dom'
import AppLayout from '../../omg-app-layout'
import PropTypes from 'prop-types'
import { getAccessToken } from '../../services/sessionService'
import { connect } from 'react-redux'
import { bootstrap } from '../bootup/action'
class AuthenticatedRoute extends Component {
  static propTypes = {
    component: PropTypes.func,
    currentAccount: PropTypes.object,
    bootstrap: PropTypes.func
  }
  componentDidMount = async () => {
    this.props.bootstrap()
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
  renderPage = (props, Component) => {
    const token = getAccessToken()
    if (!token) {
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
  null,
  { bootstrap }
)(AuthenticatedRoute)
