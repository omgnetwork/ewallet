import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Redirect, Switch } from 'react-router-dom';
import { ConnectedRouter } from 'react-router-redux';
import PropTypes from 'prop-types';
import AlertActions from '../actions/alert.actions';
import history from '../helpers/history';

import { UPDATE_PASSWORD } from './public/reset_password/ResetPasswordForm';
import { INVITATION } from './authenticated/setting/Setting';

import DevTools from './DevTools';
import AccountRouter from './authenticated/AccountRouter';
import PublicRoute from './public/PublicRoute';
import Startup from './startup/Startup';
import SignIn from './public/signin/SignIn';
import ResetPassword from './public/reset_password/ResetPassword';
import UpdatePassword from './public/update_password/UpdatePassword';

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
              <PublicRoute component={ResetPassword} path="/reset_password" />
              <PublicRoute component={UpdatePassword} path={`/${UPDATE_PASSWORD.pathname}`} />
              <PublicRoute component={UpdatePassword} path={`/${INVITATION.pathname}`} />
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
