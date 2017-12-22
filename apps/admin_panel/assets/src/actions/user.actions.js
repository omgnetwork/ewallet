import { sessionService } from "redux-react-session";
import { push } from "react-router-redux";

import { sessionAPI } from "../omisego/services";
import { alertActions } from "./";
import { handleAPIError } from "../helpers/errorHandler"
import { globalActions } from "./";

export const userActions = {
  login,
  logout
};

function login(email, password) {
  return dispatch => {
    dispatch(globalActions.showLoading())
    sessionAPI.login(email, password)
      .then(
        token => {
          const mergedTokens = `${token.user_id}:${token.authentication_token}`
          sessionService.saveSession(mergedTokens)
            .then(() => {
              dispatch(push("/accounts"));
            }).catch(error => {
              dispatch(alertActions.error(error));
            });
        },
        error => {
          handleAPIError(dispatch, error)
        }
      ).then(() => {
        dispatch(globalActions.hideLoading())
      });
  };
}

function logout() {
  return dispatch => {
    dispatch(globalActions.showLoading())
    sessionAPI.logout()
      .then(() => {
        sessionService.deleteSession()
          .then(() => {
            dispatch(push("/signin"));
          }).catch(error => {
            dispatch(alertActions.error(error));
          });
      },
      error => {
        handleAPIError(dispatch, error)
      }).then(() => {
        dispatch(globalActions.hideLoading())
      });
  };
}
