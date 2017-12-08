import React, { Component } from "react";
import { Route, Redirect } from "react-router-dom"
import PropTypes from "prop-types";

import AuthenticatedLayout from "../../layouts/AuthenticatedLayout"

class AuthenticatedRoute extends Component {

  render() {
    const { component: Component, authenticated, ...rest } = this.props
    return (
      <Route {...rest} render={props => (
        authenticated ? (
          <AuthenticatedLayout>
            <Component {...props} />
          </AuthenticatedLayout>
        ) : (
          <Redirect to={{
            pathname: "/signin",
            state: { from: props.location }
          }}/>
        )
      )} />
    );
  }
}

const { bool, func } = PropTypes;
AuthenticatedRoute.propTypes = {
  component: func.isRequired,
  authenticated: bool.isRequired,
};

export default AuthenticatedRoute;
