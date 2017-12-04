import React from "react";
import { connect } from "react-redux";
import { Route, Redirect, Switch } from "react-router-dom";
import { ConnectedRouter, routerReducer, routerMiddleware, push } from "react-router-redux";

import { alertActions } from "../actions";
import { history } from "../helpers";
import HomePage from "./HomePage";
import LoginPage from "./LoginPage";
import DevTools from "./DevTools";
import PrivateRoute from "../components/PrivateRoute";

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
    const { authentication } = this.props;

    return (
      <div className="container">
        <div className="col-sm-8 col-sm-offset-2">
          {alert.message &&
                        <div className={`alert ${alert.type}`}>
                          {alert.message}
                        </div>
          }
          <ConnectedRouter history={history}>
            { authentication.checked &&
              <div>
                <Switch>
                  <PrivateRoute exact path='/'
                    component={HomePage}
                    authenticated={authentication.authenticated}/>
                  <Route path='/login' component={LoginPage} />
                  <Redirect to="/" />
                </Switch>
              </div>
            }
          </ConnectedRouter>
        </div>
        <DevTools />
      </div>
    );
  }
}

function mapStateToProps(state) {
  const { alert } = state;
  const { session } = state;
  const authentication = {checked: session.checked,
    authenticated: session.authenticated};
  return {
    alert, authentication
  };
}

const connectedApp = connect(mapStateToProps)(App);
export { connectedApp as App };
