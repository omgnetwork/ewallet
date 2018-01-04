import React from 'react';
import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';

import PublicLayout from './PublicLayout';

const PublicRoute = ({ component: Component, ...rest }) => (
  <Route
    {...rest}
    render={params => (
      <PublicLayout>
        <Component {...params} />
      </PublicLayout>
    )}
  />
);

PublicRoute.propTypes = {
  component: PropTypes.func.isRequired,
};

export default PublicRoute;
