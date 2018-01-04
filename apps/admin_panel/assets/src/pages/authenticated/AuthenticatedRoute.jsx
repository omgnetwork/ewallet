import React from 'react';
import { Route, Redirect } from 'react-router-dom';
import PropTypes from 'prop-types';

import { alert } from '../../actions/index';
import AuthenticatedLayout from './AuthenticatedLayout';

const AuthenticatedRoute = ({ component: Component, authenticated, ...rest }) => (
  <Route
    {...rest}
    render={params =>
      (authenticated ? (
        <AuthenticatedLayout alert={alert}>
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
  authenticated: PropTypes.bool.isRequired,
};

export default AuthenticatedRoute;
