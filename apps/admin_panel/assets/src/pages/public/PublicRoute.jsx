import React from 'react';
import { Route, Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import PublicLayout from './PublicLayout';

const PublicRoute = ({ component: Component, session, ...rest }) => (
  <Route
    {...rest}
    render={params =>
      (session.currentUser ? (
        <Redirect
          to={{
            pathname: '/',
            state: { from: params.location },
          }}
        />
      ) : (
        <PublicLayout>
          <Component {...params} />
        </PublicLayout>
      )
    )}
  />
);

PublicRoute.propTypes = {
  component: PropTypes.func.isRequired,
  session: PropTypes.object.isRequired,
};

function mapStateToProps(state) {
  const { session } = state;
  return {
    session,
  };
}

export default connect(mapStateToProps)(PublicRoute);
