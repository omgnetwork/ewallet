import React from 'react';
import { Route, Redirect } from 'react-router-dom';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import AuthenticatedLayout from './AuthenticatedLayout';

const AuthenticatedRoute = ({ component: Component, session, ...rest }) => (
  <Route
    {...rest}
    render={params =>
      (session.currentUser ? (
        <AuthenticatedLayout>
          <Component {...params} />
        </AuthenticatedLayout>
      ) : (
        <Redirect
          to={{
            pathname: '/signin',
            state: { from: params.location },
          }}
        />
      ))
    }
  />
);

AuthenticatedRoute.propTypes = {
  component: PropTypes.func.isRequired,
  session: PropTypes.object.isRequired,
};

function mapStateToProps(state) {
  const { session } = state;
  return {
    session,
  };
}

export default connect(mapStateToProps)(AuthenticatedRoute);
