import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Redirect, Switch } from 'react-router-dom';
import { ConnectedRouter } from 'react-router-redux';
import PropTypes from 'prop-types';
import { alertActions } from '../actions';
import { history } from '../helpers';

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
    history.listen((location, action) => {
      // clear alert on location change
      dispatch(alertActions.clear());
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
                exact
                path="/"
                component={Home}
                authenticated={session.authenticated}
              />
              <AuthenticatedRoute
                exact
                path="/accounts"
                component={Accounts}
                authenticated={session.authenticated}
              />
              <AuthenticatedRoute
                exact
                path="/accounts/new"
                component={NewAccount}
                authenticated={session.authenticated}
              />
              <PublicRoute path="/signin" component={SignIn} />
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
  session: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  dispatch: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { session } = state;
  return {
    session,
  };
}

const connectedApp = connect(mapStateToProps)(App);
export default connectedApp;
