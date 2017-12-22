import React, { Component } from "react";
import { connect } from "react-redux";
import { Redirect, Switch } from "react-router-dom";
import { ConnectedRouter } from "react-router-redux";

import { alertActions } from "../actions";
import { history } from "../helpers";
import DevTools from "./DevTools";
import AuthenticatedRoute from "../components/routes/AuthenticatedRoute"
import PublicRoute from "../components/routes/PublicRoute"
import Home from "./authenticated/Home.jsx"
import Accounts from "./authenticated/accounts/Accounts.jsx"
import NewAccount from "./authenticated/accounts/NewAccount.jsx"
import SignIn from "./public/SignIn.jsx"

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
    const { alert } = this.props;
    const { session } = this.props;
    return (
      <ConnectedRouter history={history}>
        { session.checked &&
          <div className="container">
            <Switch>
              <AuthenticatedRoute
                exact path="/"
                component={Home}
                authenticated={session.authenticated}/>
              <AuthenticatedRoute
                exact path="/accounts"
                component={Accounts}
                authenticated={session.authenticated}/>
              <AuthenticatedRoute
                exact path="/accounts/new"
                component={NewAccount}
                authenticated={session.authenticated}/>
              <PublicRoute path="/signin" component={SignIn}/>
              <Redirect to="/signin" />
            </Switch>
            <DevTools />
          </div>
        }
      </ConnectedRouter>
    );
  }
}

function mapStateToProps(state) {
  const { session } = state;
  return {
    session
  };
}

const connectedApp = connect(mapStateToProps)(App);
export { connectedApp as App };
