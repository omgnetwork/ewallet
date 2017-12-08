import React, { Component } from "react";
import { Route } from "react-router-dom"

import PublicLayout from "../../layouts/PublicLayout"

class PublicRoute extends Component {

  render() {
    const { component: Component, ...rest } = this.props
    return (
      <Route {...rest} render={props => (
        <PublicLayout>
          <Component {...props} />
        </PublicLayout>
      )} />
    );
  }
}

export default PublicRoute;
