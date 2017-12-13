import { sessionService } from "redux-react-session";
import { push } from "react-router-redux";

import { userConstants } from "../constants";
import { sessionAPI } from "../omisego/services";
import { alertActions } from "./";

export const userActions = {
  login,
  logout
  // Surrely more to come: register / get / ...
};

function login(email, password) {
  return dispatch => {
    dispatch({ type: userConstants.LOGIN_REQUEST });
    sessionAPI.login(email, password)
      .then(
        token => {
          sessionService.saveSession(token.authentication_token)
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
    sessionAPI.logout()
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
