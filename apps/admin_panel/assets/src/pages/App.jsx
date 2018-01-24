import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Redirect, Switch } from 'react-router-dom';
import { ConnectedRouter } from 'react-router-redux';
import PropTypes from 'prop-types';
import AlertActions from '../actions/alert.actions';
import history from '../helpers/history';

import DevTools from './DevTools';
import AccountRouter from './authenticated/AccountRouter';
import PublicRoute from './public/PublicRoute';
import Startup from './startup/Startup';
import SignIn from './public/signin/SignIn';
import ForgotPassword from './public/forgot_password/ForgotPassword';
import ResetPassword from './public/reset_password/ResetPassword';

class App extends Component {
  constructor(props) {
    super(props);

    const { dispatch } = this.props;
    history.listen(() => {
      // clear alert on location change
      dispatch(AlertActions.clear());
    });
  }

  render() {
    // const { alert } = this.props;
    return (
      <Startup>
        <ConnectedRouter history={history}>
          <div className="container">
            <Switch>
              <PublicRoute component={SignIn} path="/signin" />
              <PublicRoute component={ForgotPassword} path="/forgot_password" />
              <PublicRoute component={ResetPassword} path="/reset_password" />
              <AccountRouter path="/a/:id" />
              <AccountRouter path="/" />
              <Redirect to="/signin" />
            </Switch>
            <DevTools />
          </div>
        </ConnectedRouter>
      </Startup>
    );
  }
}

App.propTypes = {
  // alert: PropTypes.func.isRequired,
  dispatch: PropTypes.func.isRequired,
};
const connectApp = connect()(App);
export default connectApp;
