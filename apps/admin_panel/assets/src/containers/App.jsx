import React from "react";
import { connect } from "react-redux";
import { Route, Redirect, Switch } from "react-router-dom";
import { ConnectedRouter } from "react-router-redux";

import { alertActions } from "../actions";
import { history } from "../helpers";
import HomePage from "./HomePage";
import SignInPage from "./SignInPage";
import DevTools from "./DevTools";
import PrivateRoute from "../components/PrivateRoute";
import ExternalHeader from "../components/ExternalHeader"
import ExternalFooter from "../components/ExternalFooter"
import Alerter from "../components/Alerter"

class App extends React.Component {

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
          <div>
            <ExternalHeader authenticated={session.authenticated} />
            <section className="external-container">
              <Alerter alert={alert} />
              <Switch>
                <PrivateRoute exact path='/'
                  component={HomePage}
                  authenticated={session.authenticated}/>
                <Route path='/login' component={SignInPage} />
                <Redirect to="/" />
              </Switch>
            </section>
            <ExternalFooter />
            <DevTools />
          </div>
        }
      </ConnectedRouter>
    );
  }
}

function mapStateToProps(state) {
  const { alert } = state;
  const { session } = state;
  return {
    alert, session
  };
}

const connectedApp = connect(mapStateToProps)(App);
export { connectedApp as App };
