import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Redirect, Switch, withRouter } from 'react-router-dom';
import { ConnectedRouter } from 'react-router-redux';
import PropTypes from 'prop-types';
import AlertActions from '../actions/alert.actions';
import history from '../helpers/history';

import DevTools from './DevTools';
import AuthenticatedRoute from './authenticated/AuthenticatedRoute';
import PublicRoute from './public/PublicRoute';
import Home from './authenticated/home/Home';
import Accounts from './authenticated/accounts/list/Accounts';
import NewAccount from './authenticated/accounts/new/NewAccount';
import Users from './authenticated/users/list/Users';
import NewUser from './authenticated/users/new/NewUser';
import SignIn from './public/signin/SignIn';
import APIManagement from './authenticated/api_management/APIManagement';
import Report from './authenticated/report/Report';
import Transactions from './authenticated/transactions/Transactions';
import Setting from './authenticated/setting/Setting';
import Tokens from './authenticated/tokens/Tokens';

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
    const { session } = this.props;
    return (
      <ConnectedRouter history={history}>
        {session.checked && (
          <div className="container">
            <Switch>
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Home}
                exact
                path="/"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Accounts}
                exact
                path="/accounts"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={NewAccount}
                exact
                path="/accounts/new"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={APIManagement}
                exact
                path="/api_management"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Report}
                exact
                path="/report"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Transactions}
                exact
                path="/transactions"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Users}
                exact
                path="/users"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={NewUser}
                exact
                path="/users/new"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Tokens}
                exact
                path="/tokens"
              />
              <AuthenticatedRoute
                authenticated={session.authenticated}
                component={Setting}
                exact
                path="/setting"
              />
              <PublicRoute component={withRouter(SignIn)} path="/signin" />
              <Redirect to="/signin" />
            </Switch>
            <DevTools />
          </div>
        )}
      </ConnectedRouter>
    );
  }
}

App.propTypes = {
  // alert: PropTypes.func.isRequired,
  dispatch: PropTypes.func.isRequired,
  session: PropTypes.object.isRequired,
};

function mapStateToProps(state) {
  const { session } = state;
  return {
    session,
  };
}

const connectedApp = connect(mapStateToProps)(App);
export default connectedApp;
