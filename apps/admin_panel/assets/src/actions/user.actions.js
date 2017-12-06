import { sessionService } from "redux-react-session";
import { push } from "react-router-redux";

import { userConstants } from "../constants";
import { sessionAPI } from "../omisego/services";
import { alertActions } from "./";
import { authHeader } from "../helpers";

export const userActions = {
  login,
  logout
  // Surrely more to come: register / get / ...
};

function login(username, password) {
  return dispatch => {
    dispatch({ type: userConstants.LOGIN_REQUEST });
    sessionAPI.login(username, password)
      .then(
        token => {
          sessionService.saveSession(token.session_token)
            .then(() => {
              dispatch({ type: userConstants.LOGIN_SUCCESS });
              dispatch(push("/"));
            }).catch(error => {
              dispatch({ type: userConstants.LOGOUT_FAILURE, error });
              dispatch(alertActions.error(error));
            });
        },
        error => {
          dispatch({ type: userConstants.LOGIN_FAILURE, error });
          dispatch(alertActions.error(error.description));
        }
      );
  };
}

function logout() {
  return dispatch => {
    dispatch({ type: userConstants.LOGOUT_REQUEST });
    sessionAPI.logout(authHeader())
      .then(() => {
        sessionService.deleteSession()
          .then(() => {
            dispatch({ type: userConstants.LOGOUT_SUCCESS });
            dispatch(push("/login"));
          }).catch(error => {
            dispatch({ type: userConstants.LOGOUT_FAILURE, error });
            dispatch(alertActions.error(error));
          });
      },
      error => {
        dispatch({ type: userConstants.LOGOUT_FAILURE, error });
        dispatch(alertActions.error(error.description));
      });
  };
}
