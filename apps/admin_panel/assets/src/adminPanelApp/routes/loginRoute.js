import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Route } from 'react-router-dom'

import AuthFormLayout from '../../omg-layout/authFormLayout'

class LoginRoute extends Component {
  static propTypes = {
    component: PropTypes.oneOfType([PropTypes.node, PropTypes.func, PropTypes.object])
  }

  render () {
    const { component: Component, ...rest } = this.props

    return (
      <Route
        {...rest}
        render={() => (
          <AuthFormLayout key={this.props}>
            <Component />
          </AuthFormLayout>
        )}
      />
    )
  }
}

export default LoginRoute
