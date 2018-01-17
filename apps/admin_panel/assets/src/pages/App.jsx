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
import Transactions from './authenticated/transactions/list/Transactions';
import NewTransaction from './authenticated/transactions/new/NewTransaction';
import Setting from './authenticated/setting/Setting';
import Tokens from './authenticated/tokens/list/Tokens';
import Admins from './authenticated/admins/list/Admins';
import NewToken from './authenticated/tokens/new/NewToken';
import Profile from './authenticated/profile/Profile';
import Startup from './startup/Startup';

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
              <AuthenticatedRoute component={Home} exact path="/" />
              <AuthenticatedRoute component={Accounts} exact path="/accounts" />
              <AuthenticatedRoute component={NewAccount} exact path="/accounts/new" />
              <AuthenticatedRoute component={APIManagement} exact path="/api_management" />
              <AuthenticatedRoute component={Admins} exact path="/admins" />
              <AuthenticatedRoute component={Report} exact path="/report" />
              <AuthenticatedRoute component={Transactions} exact path="/transactions" />
              <AuthenticatedRoute component={NewTransaction} exact path="/transactions/new" />
              <AuthenticatedRoute component={Users} exact path="/users" />
              <AuthenticatedRoute component={NewUser} exact path="/users/new" />
              <AuthenticatedRoute component={Tokens} exact path="/tokens" />
              <AuthenticatedRoute component={NewToken} exact path="/tokens/new" />
              <AuthenticatedRoute component={Setting} exact path="/setting" />
              <AuthenticatedRoute component={withRouter(Profile)} exact path="/profile" />
              <PublicRoute component={SignIn} path="/signin" />
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
