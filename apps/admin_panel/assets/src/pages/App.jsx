import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Redirect, Switch } from 'react-router-dom';
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
import SignIn from './public/signin/SignIn';

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
              <PublicRoute component={SignIn} path="/signin" />
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
